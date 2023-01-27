#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# Version: 2.0

# to be run as root, probably as a user-script just after a server is installed
# https://stackoverflow.com/a/52586842/1004587
# also see https://stackoverflow.com/q/3522341/1004587
is_user_root () { [ "${EUID:-$(id -u)}" -eq 0 ]; }
[ is_user_root ] || { echo 'You must be root or have sudo privilege to run this script. Exiting now.'; exit 1; }

export PATH=~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
export DEBIAN_FRONTEND=noninteractive

echo "Script started on (date & time): $(date +%c)"

# Defining return code check function
check_result() {
    if [ $? -ne 0 ]; then
        echo; echo "Error: $1"; echo
        exit 1
    fi
}

if [ ! -f "$HOME/.envrc" ]; then
    touch ~/.envrc
    chmod 600 ~/.envrc
else
    . ~/.envrc
fi

git_usermail=${EMAIL:-root@localhost}
git_username=${NAME:-root}

#--- apt tweaks ---#

# Ref: https://wiki.debian.org/Multiarch/HOWTO
# https://askubuntu.com/a/1336013/65814
[ ! $(dpkg --get-selections | grep -q i386) ] && dpkg --remove-architecture i386 2>/dev/null

# Fix apt ipv4/6 issue
echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/1000-force-ipv4-transport

# Fix a warning related to dialog
# run `debconf-show debconf` to see the current /default selections.
echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# the following runs when apt cache is older than 6 hours
if [ -z "$(find /var/cache/apt/pkgcache.bin -mmin -360 2> /dev/null)" ]; then
        printf '%-72s' "Updating apt cache"
        apt-get -qq update
        echo done.
fi

echo -------------------------- Prerequisites ------------------------------------
# apt-utils to fix an annoying non-critical bug on minimal images. Ref: https://github.com/tianon/docker-brew-ubuntu-core/issues/59
# powermgmt-base to fix a warning in unattended-upgrade.log
required_packages="apt-utils \
    fail2ban \
    powermgmt-base \
    tzdata"

for package in $required_packages
do
    if dpkg-query -w -f='${status}' $package 2>/dev/null | grep -q "ok installed"
    then
        # echo "'$package' is already installed"
        :
    else
        printf '%-72s' "Installing '${package}' ..."
        apt-get -qq install $package > /dev/null
        check_result "Error: couldn't install $package."
        echo done.
    fi
done

#--- setup timezone ---#
current_time_zone=$(date +\%Z)
if [ "$current_time_zone" != "UTC" ] ; then
    printf '%-72s' "Setting up timezone..."
    ln -fs /usr/share/zoneinfo/UTC /etc/localtime
    dpkg-reconfigure -f noninteractive tzdata
    # timedatectl set-timezone UTC
    check_result $? 'Error setting up timezone.'
    systemctl restart cron
    check_result $? 'Error restarting cron daemon.'
    echo done.
fi

echo ---------------------------------- LEMP -------------------------------------

php_ver=8.1
lemp_packages="nginx-extras \
    default-mysql-server \
    php${php_ver}-fpm \
    php${php_ver}-mysql \
    php${php_ver}-gd \
    php${php_ver}-cli \
    php${php_ver}-xml \
    php${php_ver}-mbstring \
    php${php_ver}-soap \
    php${php_ver}-curl \
    php${php_ver}-zip \
    php${php_ver}-bcmath \
    php${php_ver}-intl \
    php${php_ver}-imagick"

for package in $lemp_packages
do
    if dpkg-query -W -f='${Status}' $package 2>/dev/null | grep -q "ok installed"
    then
        echo "'$package' is already installed"
        :
    else
        # Remove ${php_ver} from package name to find if php-package is installed.
        php_package=$(printf '%s' "$package" | sed 's/[.0-9]*//g')
        if dpkg-query -W -f='${Status}' $php_package 2>/dev/null | grep -q "ok installed"
        then
            echo "'$package' is already installed as $php_package"
            :
        else
            printf '%-72s' "Installing '${package}' ..."
            apt-get -qq install $package > /dev/null
            check_result $? "Error installing ${package}."
            echo done.
        fi
    fi
done

# Download WordPress Nginx repo
[ ! -d ~/wp-nginx ] && {
    mkdir ~/wp-nginx
    wget -q -O- https://github.com/pothi/wordpress-nginx/tarball/main | tar -xz -C ~/wp-nginx --strip-components=1
    cp -a ~/wp-nginx/{conf.d,errors,globals,sites-available} /etc/nginx/
    [ ! -d /etc/nginx/sites-enabled ] && mkdir /etc/nginx/sites-enabled
    ln -fs /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf
}

# Remove the default conf file supplied by OS
[ -f /etc/nginx/sites-enabled/default ] && rm /etc/nginx/sites-enabled/default

# Remove the default SSL conf to support latest SSL conf.
# It should hide two lines starting with ssl_
# ^ starting with...
# \s* matches any number of space or tab elements before ssl_
# when run more than once, it just doesn't do anything as the start of the line is '#' after the first execution.
sed -i 's/^\s*ssl_/# &/' /etc/nginx/nginx.conf 

# create dhparam
if [ ! -f /etc/nginx/dhparam.pem ]; then
    openssl dhparam -dsaparam -out /etc/nginx/dhparam.pem 4096 > /dev/null
    sed -i 's:^# \(ssl_dhparam /etc/nginx/dhparam.pem;\)$:\1:' /etc/nginx/conf.d/ssl-common.conf
fi

echo -----------------------------------------------------------------------------
echo "Please check ~/.envrc for all the credentials."
echo -----------------------------------------------------------------------------

if [ "$ADMIN_USER" == "" ]; then
printf '%-72s' "Creating a MySQL Admin User..."
    # create MYSQL username automatically
    # unique username / password generator: https://unix.stackexchange.com/q/230673/20241
    ADMIN_USER="sql_$(openssl rand -base64 32 | tr -d /=+ | cut -c -10)"
    ADMIN_PASS=$(openssl rand -base64 32 | tr -d /=+ | cut -c -20)
    echo "export ADMIN_USER=$ADMIN_USER" >> /root/.envrc
    echo "export ADMIN_PASS=$ADMIN_PASS" >> /root/.envrc
    mysql -e "CREATE USER ${ADMIN_USER} IDENTIFIED BY '${ADMIN_PASS}';"
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO ${ADMIN_USER} WITH GRANT OPTION"
echo done.
echo "Please check ~/.envrc for credentials."
fi

wp_user=${WP_USERNAME:-""}
if [ "$wp_user" == "" ]; then
printf '%-72s' "Creating a WP User..."
    wp_user="wp_$(openssl rand -base64 32 | tr -d /=+ | cut -c -10)"
    echo "export WP_USERNAME=$wp_user" >> /root/.envrc
echo done.
fi

wp_pass=${WP_PASSWORD:-""}
if [ "$wp_pass" == "" ]; then
printf '%-72s' "Creating password for WP user..."
    wp_pass=$(openssl rand -base64 32 | tr -d /=+ | cut -c -20)
    echo "export WP_PASSWORD=$wp_pass" >> /root/.envrc

    echo "$wp_user:$wp_pass" | chpasswd
echo done.
fi

# home_basename=$(echo $wp_user | awk -F _ '{print $1}')
# [ -z $home_basename ] && home_basename=web
home_basename=web

if [ ! -d "/home/${home_basename}" ]; then
    useradd --shell=/bin/bash -m --home-dir /home/${home_basename} $wp_user
    chmod 755 /home/$home_basename

    groupadd ${home_basename}
    gpasswd -a $wp_user ${home_basename} > /dev/null
fi

# provide sudo access without passwd to WP Dev
if [ ! -f /etc/sudoers.d/$wp_user ]; then
printf '%-72s' "Providing sudo privilege for WP user..."
    echo "${wp_user} ALL=(ALL) NOPASSWD:ALL"> /etc/sudoers.d/$wp_user
    chmod 400 /etc/sudoers.d/$wp_user
echo done.
fi

cd /etc/ssh/sshd_config.d
if [ ! -f enable-passwd-auth.conf ]; then
printf '%-72s' "Enabling Password Authentication for WP user..."
    echo "PasswordAuthentication yes" > enable-passwd-auth.conf
    /usr/sbin/sshd -t && systemctl restart sshd
    check_result $? 'Error restarting SSH daemon while enabling passwd auth.'
echo done.
fi
cd - 1> /dev/null

# . $local_wp_in_a_box_repo/scripts/php-installation.sh
php_user=$wp_user
fpm_ini_file=/etc/php/${php_ver}/fpm/php.ini
pool_file=/etc/php/${php_ver}/fpm/pool.d/${php_user}.conf
PM_METHOD=ondemand

user_mem_limit=${PHP_MEM_LIMIT:-""}
[ -z "$user_mem_limit" ] && user_mem_limit=256

max_children=${PHP_MAX_CHILDREN:-""}

if [ -z "$max_children" ]; then
    # let's be safe with a minmal value
    sys_memory=$(free -m | grep -oP '\d+' | head -n 1)
    if (($sys_memory <= 600)) ; then
        max_children=4
    elif (($sys_memory <= 1600)) ; then
        max_children=6
    elif (($sys_memory <= 5600)) ; then
        max_children=10
    elif (($sys_memory <= 10600)) ; then
        PM_METHOD=static
        max_children=20
    elif (($sys_memory <= 20600)) ; then
        PM_METHOD=static
        max_children=40
    elif (($sys_memory <= 30600)) ; then
        PM_METHOD=static
        max_children=60
    elif (($sys_memory <= 40600)) ; then
        PM_METHOD=static
        max_children=80
    else
        PM_METHOD=static
        max_children=100
    fi
fi

env_type=${ENV_TYPE:-""}
if [[ $env_type = "local" ]]; then
    PM_METHOD=ondemand
fi

echo "Configuring memory limit to ${user_mem_limit}MB"
sed -i -e '/^memory_limit/ s/=.*/= '$user_mem_limit'M/' $fpm_ini_file

user_max_filesize=${PHP_MAX_FILESIZE:-64}
echo "Configuring 'post_max_size' and 'upload_max_filesize' to ${user_max_filesize}MB..."
sed -i -e '/^post_max_size/ s/=.*/= '$user_max_filesize'M/' $fpm_ini_file
sed -i -e '/^upload_max_filesize/ s/=.*/= '$user_max_filesize'M/' $fpm_ini_file

user_max_input_vars=${PHP_MAX_INPUT_VARS:-5000}
echo "Configuring 'max_input_vars' to $user_max_input_vars (from the default 1000)..."
sed -i '/max_input_vars/ s/;\? \?\(max_input_vars \?= \?\)[[:digit:]]\+/\1'$user_max_input_vars'/' $fpm_ini_file

# Setup timezone
user_timezone=${USER_TIMEZONE:-UTC}
echo "Configuring timezone to $user_timezone ..."
sed -i -e 's/^;date\.timezone =$/date.timezone = "'$user_timezone'"/' $fpm_ini_file
export PHP_PCNTL_FUNCTIONS='pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wifcontinued,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_get_handler,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,pcntl_async_signals,pcntl_unshare'
export PHP_EXEC_FUNCTIONS='escapeshellarg,escapeshellcmd,exec,passthru,proc_close,proc_get_status,proc_nice,proc_open,proc_terminate,shell_exec,system'
sed -i "/disable_functions/c disable_functions = ${PHP_PCNTL_FUNCTIONS},${PHP_EXEC_FUNCTIONS}" $fpm_ini_file

[ ! -f $pool_file ] && cp /etc/php/${php_ver}/fpm/pool.d/www.conf $pool_file
sed -i -e 's/^\[www\]$/['$php_user']/' $pool_file
sed -i -e 's/www-data/'$php_user'/' $pool_file
sed -i -e '/^;listen.\(owner\|group\|mode\)/ s/^;//' $pool_file
sed -i -e '/^listen.mode = / s/[0-9]\{4\}/0666/' $pool_file

php_ver_short=$(echo $php_ver | sed 's/\.//')
socket=/run/php/fpm-${php_ver_short}-${php_user}.sock
sed -i "/^listen =/ s:=.*:= $socket:" $pool_file
# [ -f /etc/nginx/conf.d/lb.conf ] && sed -i "s:/var/lock/php-fpm.*;:$socket;:" /etc/nginx/conf.d/lb.conf
[ -f /etc/nginx/conf.d/lb.conf ] && rm /etc/nginx/conf.d/lb.conf
[ ! -f /etc/nginx/conf.d/fpm.conf ] && echo "upstream fpm { server unix:$socket; }" > /etc/nginx/conf.d/fpm.conf
[ ! -f /etc/nginx/conf.d/fpm${php_ver_short}.conf ] && echo "upstream fpm${php_ver_short} { server unix:$socket; }" > /etc/nginx/conf.d/fpm${php_ver_short}.conf

sed -i -e 's/^pm = .*/pm = '$PM_METHOD'/' $pool_file
sed -i '/^pm.max_children/ s/=.*/= '$max_children'/' $pool_file

PHP_MIN=$(expr $max_children / 10)

sed -i '/^;catch_workers_output/ s/^;//' $pool_file
sed -i '/^;pm.process_idle_timeout/ s/^;//' $pool_file
sed -i '/^;pm.max_requests/ s/^;//' $pool_file
sed -i '/^;pm.status_path/ s/^;//' $pool_file
sed -i '/^;ping.path/ s/^;//' $pool_file
sed -i '/^;ping.response/ s/^;//' $pool_file

# home_basename=web
# home_basename=$(echo $wp_user | awk -F _ '{print $1}')
# [ -z $home_basename ] && home_basename=web
# [ ! -d /home/${home_basename}/log ] && mkdir /home/${home_basename}/log
PHP_SLOW_LOG_PATH="/var/log/slow-php.log"
sed -i '/^;slowlog/ s/^;//' $pool_file
sed -i '/^slowlog/ s:=.*$: = '$PHP_SLOW_LOG_PATH':' $pool_file
sed -i '/^;request_slowlog_timeout/ s/^;//' $pool_file
sed -i '/^request_slowlog_timeout/ s/= .*$/= 60/' $pool_file

FPMCONF="/etc/php/${php_ver}/fpm/php-fpm.conf"
sed -i '/^;emergency_restart_threshold/ s/^;//' $FPMCONF
sed -i '/^emergency_restart_threshold/ s/=.*$/= '$PHP_MIN'/' $FPMCONF
sed -i '/^;emergency_restart_interval/ s/^;//' $FPMCONF
sed -i '/^emergency_restart_interval/ s/=.*$/= 1m/' $FPMCONF
sed -i '/^;process_control_timeout/ s/^;//' $FPMCONF
sed -i '/^process_control_timeout/ s/=.*$/= 10s/' $FPMCONF

# restart php upon OOM or other failures
# ref: https://stackoverflow.com/a/45107512/1004587
# TODO: Do the following only if "Restart=on-failure" is not found in that file.
sed -i '/^\[Service\]/!b;:a;n;/./ba;iRestart=on-failure' /lib/systemd/system/php${php_ver}-fpm.service
systemctl daemon-reload
check_result $? "Could not update /lib/systemd/system/php${php_ver}-fpm.service file!"

printf '%-72s' "Restarting PHP-FPM..."
/usr/sbin/php-fpm${php_ver} -t 2>/dev/null && systemctl restart php${php_ver}-fpm
echo done.

printf '%-72s' "Restarting Nginx..."
/usr/sbin/nginx -t 2>/dev/null && systemctl restart nginx
echo done.

echo --------------------------- Certbot -----------------------------------------
snap install core
snap refresh core
apt-get -qq remove certbot
snap install --classic certbot
ln -fs /snap/bin/certbot /usr/bin/certbot

# register certbot account if email is supplied
if [ $CERTBOT_ADMIN_EMAIL ]; then
    certbot show_account &> /dev/null
    if [ "$?" != "0" ]; then
        certbot -m $CERTBOT_ADMIN_EMAIL --agree-tos --no-eff-email register
    fi
fi

[ ! -d /etc/letsencrypt/renewal-hooks/deploy/ ] && mkdir -p /etc/letsencrypt/renewal-hooks/deploy/
restart_script=/etc/letsencrypt/renewal-hooks/deploy/nginx-restart.sh
restart_script_url=https://github.com/pothi/snippets/raw/main/ssl/nginx-restart.sh
[ ! -f "$restart_script" ] && {
    wget -q -O $restart_script $restart_script_url
    check_result $? "Error downloading Nginx Restart Script for Certbot renewals."
    chmod +x $restart_script
}

echo All done.

echo -----------------------------------------------------------------------------
echo You may find the login credentials of SFTP/SSH user in /root/.envrc file.
echo -----------------------------------------------------------------------------

echo 'You may reboot only once to apply certain updates (ex: kernel updates)!'
echo

echo "Script ended on (date & time): $(date +%c)"
echo
