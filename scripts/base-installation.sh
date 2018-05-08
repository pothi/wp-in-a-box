#!/bin/bash

#--- Install pre-requisites ---#
# landscape-common update-notifier-common \
echo 'Install prerequisites. It may take some time to complete...'
required_packages="acl \
    bash-completion \
    dnsutils \
    mlocate \
    unattended-upgrades apt-listchanges \
    zip unzip  \
    python-pip \
    pwgen \
    fail2ban \
    bc"

for package in $required_packages
do  
    echo -n "Installing ${package}..."
    DEBIAN_FRONTEND=noninteractive apt-get -qq install $package &> /dev/null
    echo " done."
done
echo "Done installing required packages."

# install AWS cli
pip_cli=$(which pip)
# created issue for many
# $pip_cli install --upgrade pip
echo -n "Installing awscli... "
$pip_cli install awscli &> /dev/null
echo 'done.'

optional_packages="apt-file \
    vim-scripts \
    nodejs npm \
    direnv \
    duplicity"

# TODO - ask user consent
# for package in $optional_packages
# do  
    # echo -n "Installing ${package}..."
    # DEBIAN_FRONTEND=noninteractive apt-get install -y $package
    # echo "done."
# done

#--- setup timezone ---#
echo -n 'Setting up timezone... '
ln -fs /usr/share/zoneinfo/UTC /etc/localtime
dpkg-reconfigure -f noninteractive tzdata &> /dev/null
# timedatectl set-timezone UTC
if [ $? != 0 ]; then
    echo 'Error setting up timezone'
fi
echo " done."

#--- Unattended Upgrades ---#
echo 'APT::Periodic::Update-Package-Lists "1";' > /etc/apt/apt.conf.d/20auto-upgrades
echo 'APT::Periodic::Unattended-Upgrade "1";' > /etc/apt/apt.conf.d/20auto-upgrades

# sed -i '/Unattended\-Upgrade::Mail/ s:^//::' /etc/apt/apt.conf.d/50unattended-upgrades
# sed -i '/Unattended-Upgrade::MailOnlyOnError/ s:^//::' /etc/apt/apt.conf.d/50unattended-upgrades
# if the following doesn't work, comment it and then uncomment the above two lines
sed -i '/\/\/Unattended-Upgrade::Mail\(OnlyOnError\)\?/ s:^//::' /etc/apt/apt.conf.d/50unattended-upgrades

#--- Setup direnv ---#
# if ! grep 'direnv' /root/.bashrc ; then
    # echo 'eval "$(direnv hook bash)"' >> /root/.bashrc
# fi

if [ -f /root/.envrc ]; then
    chmod 600 /root/.envrc
    source /root/.envrc
    # direnv allow &> /dev/null
fi


#--- Setup some helper tools ---#
if [ ! -s /root/ps_mem.py ]; then
    echo -n 'Downloading ps_mem.py... '
    PSMEMURL=http://www.pixelbeat.org/scripts/ps_mem.py
    wget -q -O /root/ps_mem.py $PSMEMURL
    chmod +x /root/ps_mem.py
    echo "done."
fi

if [ ! -s /root/scripts/mysqltuner.pl ]; then
    echo -n 'Downloading mysqltuner... '
    TUNERURL=https://raw.github.com/major/MySQltuner-perl/master/mysqltuner.pl
    wget -q -O /root/scripts/mysqltuner.pl $TUNERURL
    chmod +x /root/scripts/mysqltuner.pl
    echo "done."
fi

if [ ! -s /root/scripts/tuning-primer.sh ]; then
    echo -n 'Downloading tuning-primer... '
    PRIMERURL=https://launchpad.net/mysql-tuning-primer/trunk/1.6-r1/+download/tuning-primer.sh
    wget -q -O /root/scripts/tuning-primer.sh $PRIMERURL
    chmod +x /root/scripts/tuning-primer.sh
    sed -i 's/\bjoin_buffer\b/&_size/' /root/scripts/tuning-primer.sh
    echo "done."
fi


#--- Setup wp cli ---#
if [ ! -s /usr/local/bin/wp ]; then
    echo -n 'Setting up WP CLI '
    WPCLIURL=https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    curl -LSsO $WPCLIURL
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp

    # auto-update wp-cli
    crontab -l | grep -qw wp-cli
    if [ "$?" -ne "0" ]; then
        ( crontab -l; echo; echo "# auto-update wp-cli" ) | crontab -
        ( crontab -l; echo '20  10  *   *   *   /usr/local/bin/wp cli update --allow-root --yes &> /dev/null' ) | crontab -
    fi

    echo "done."

fi

#--- auto-renew SSL certs ---#
# check for the line with the text "certbot"
crontab -l | grep -qw certbot
if [ "$?" -ne "0" ]; then
    ( crontab -l; echo; echo "# auto-renew SSL certs" ) | crontab -
    ( crontab -l; echo '36   0,12   *   *   *   /usr/bin/certbot renew --post-hook "/usr/sbin/nginx -t && /usr/sbin/service nginx reload" &> /dev/null' ) | crontab -
fi


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
