#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

export DEBIAN_FRONTEND=noninteractive

# what's done here

# variables

#--- Install pre-requisites ---#
# landscape-common update-notifier-common \
echo Installing prerequisites...
echo -----------------------------------------------------------------------------
required_packages="apt-transport-https \
    bash-completion \
    dnsutils \
    language-pack-en \
    unattended-upgrades apt-listchanges \
    pwgen \
    fail2ban \
    sudo \
    tzdata \
    unzip"

for package in $required_packages
do
    # if dpkg-query -s $package &> /dev/null
    if dpkg-query -W -f='${Status}' $package | grep -q "ok installed"
    then
        echo "$package is already installed"
    else
        printf '%-72s' "Installing ${package}..."
        apt-get -qq install $package &> /dev/null
        echo done.
    fi
done

echo -------------------------------------------------------------------------
echo ... done installing prerequisites!
echo

if [ ! -s /var/spool/cron/crontabs/root ]; then
echo 'Setting up crontab for root!'
echo '
# ┌───────────── minute (0 - 59)
# │ ┌───────────── hour (0 - 23)
# │ │ ┌───────────── day of month (1 - 31)
# │ │ │ ┌───────────── month (1 - 12)
# │ │ │ │ ┌───────────── day of week (0 - 6) (Sunday to Saturday;
# │ │ │ │ │                                       7 is also Sunday on some systems)
# │ │ │ │ │
# │ │ │ │ │
# * * * * *  command to execute' | crontab - &>> $log_file
fi

web_dev=${DEV_USER:-""}
if [ ! -z "$web_dev" ]; then
    # set up some defaults
    if [ ! -s /var/spool/cron/crontabs/$web_dev ]; then
        echo "Setting up crontab for $web_dev!"
        echo '
        # ┌───────────── minute (0 - 59)
        # │ ┌───────────── hour (0 - 23)
        # │ │ ┌───────────── day of month (1 - 31)
        # │ │ │ ┌───────────── month (1 - 12)
        # │ │ │ │ ┌───────────── day of week (0 - 6) (Sunday to Saturday;
        # │ │ │ │ │                                       7 is also Sunday on some systems)
        # │ │ │ │ │
        # │ │ │ │ │
        # * * * * *  command to execute' | crontab -u $web_dev - &>> $log_file
    fi
fi

#--- setup timezone ---#
current_time_zone=$(date +\%Z)
if [ "$current_time_zone" != "UTC" ] ; then
    printf '%-72s' "Setting up timezone..."
    ln -fs /usr/share/zoneinfo/UTC /etc/localtime
    dpkg-reconfigure -f noninteractive tzdata &>> $log_file
    # timedatectl set-timezone UTC
    check_result $? 'Error setting up timezone.'
    systemctl restart cron
    check_result $? 'Error restarting cron daemon.'
    echo done.
fi

# printf '%-72s' "Setting up timezone..."
#--- Unattended Upgrades ---#
echo 'APT::Periodic::Update-Package-Lists "1";' >| /etc/apt/apt.conf.d/20auto-upgrades
echo 'APT::Periodic::Unattended-Upgrade "1";' >> /etc/apt/apt.conf.d/20auto-upgrades

# sed -i '/Unattended\-Upgrade::Mail/ s:^//::' /etc/apt/apt.conf.d/50unattended-upgrades
# sed -i '/Unattended-Upgrade::MailOnlyOnError/ s:^//::' /etc/apt/apt.conf.d/50unattended-upgrades
# if the following doesn't work, comment it and then uncomment the above two lines
sed -i '/\/\/Unattended-Upgrade::Mail\(OnlyOnError\)\?/ s:^//::' /etc/apt/apt.conf.d/50unattended-upgrades
# echo done.

#--- setup permissions for .envrc file ---#
if [ -f /root/.envrc ]; then
    chmod 600 /root/.envrc
    . /root/.envrc
    # direnv allow &> /dev/null
fi

#--- Setup wp cli ---#
if [ ! -s /usr/local/bin/wp ]; then
    printf '%-72s' "Setting up WP CLI..."
    wp_cli_url=https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    curl -LSsO $wp_cli_url
    check_result $? 'wp-cli: error downloading the script.'
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp

    echo done.
fi

# wp cli bash completion
if [ ! -s /etc/bash_completion.d/wp-completion.bash ]; then
    curl -LSso /etc/bash_completion.d/wp-completion.bash https://github.com/wp-cli/wp-cli/raw/master/utils/wp-completion.bash
fi

#--- cron: auto-update wp-cli ---#
grep -qw wp-cli /var/spool/cron/crontabs/root
if [ "$?" -ne "0" ]; then
    ( crontab -l; echo; echo "# auto-update wp-cli" ) | crontab -
    ( crontab -l; echo '@daily /usr/local/bin/wp cli update --allow-root --yes &> /dev/null' ) | crontab -
fi

#--- auto-renew SSL certs ---#
# check for the line with the text "certbot"
crontab -l | grep -qw certbot
if [ $? -ne 0 ]; then
    ( crontab -l; echo; echo "# auto-renew SSL certs" ) | crontab -
    ( crontab -l; echo '@daily /usr/bin/certbot renew --post-hook "/usr/sbin/nginx -t && /usr/sbin/service nginx reload" &> /dev/null' ) | crontab -
fi


#--- cron tweaks ---#
#--- separate cron log ---#
# if ! grep -q '# Log cron stuff' /etc/rsyslog.conf ; then
    # echo '# Log cron stuff' > /etc/rsyslog.conf
    # echo "cron.*    /var/log/cron" >> /etc/rsyslog.conf
# fi
sed -i -e 's/^#cron.*/cron.*/' /etc/rsyslog.conf

#- log only errors -#
# the following solution may not work in the future, as /etc/default/cron is being deprecated!
sed -i -e 's/^#EXTRA_OPTS=""$/EXTRA_OPTS=""/' -e 's/^EXTRA_OPTS=""$/EXTRA_OPTS="-L 0"/' /etc/default/cron
systemctl restart syslog
systemctl restart cron

