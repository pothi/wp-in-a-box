#!/bin/bash

# TODO
# - Setup error log inside the user's home / log directory

# Variable/s
# WP_SFTP_USER=
# PHP_MAX_CHILDREN=
# MY_MEMCACHED_MEMORY
# PM_METHOD

echo "Setting up PHP..."

# get the variables
source /root/.envrc

PM_METHOD=ondemand

if [ -z "$WP_SFTP_USER" ]; then
    echo 'SFTP User is not found. Exiting prematurely!'; exit
fi

if [ -z "$PHP_MAX_CHILDREN" ]; then
    # let's be safe with a minmal value
    sys_memory=$(free -m | grep -oP '\d+' | head -n 1)
    if (($sys_memory <= 600)) ; then
        PHP_MAX_CHILDREN=4
    elif (($sys_memory <= 1600)) ; then
        PHP_MAX_CHILDREN=6
    elif (($sys_memory <= 5600)) ; then
        PHP_MAX_CHILDREN=10
    elif (($sys_memory <= 10600)) ; then
        PM_METHOD=static
        PHP_MAX_CHILDREN=20
    elif (($sys_memory <= 20600)) ; then
        PM_METHOD=static
        PHP_MAX_CHILDREN=40
    elif (($sys_memory <= 30600)) ; then
        PM_METHOD=static
        PHP_MAX_CHILDREN=60
    elif (($sys_memory <= 40600)) ; then
        PM_METHOD=static
        PHP_MAX_CHILDREN=80
    else
        PM_METHOD=static
        PHP_MAX_CHILDREN=100
    fi
fi

if [ -z "$PHP_MEM_LIMIT" ]; then
    # let's be safe with a minmal value
    PHP_MEM_LIMIT=256
fi

# LOG_FILE="/root/log/php-install.log"
# exec > >(tee -a ${LOG_FILE} )
# exec 2> >(tee -a ${LOG_FILE} >&2)

# php${PHP_VER}-mysqlnd package is not found in Ubuntu

codename=`lsb_release -c -s`
case "$codename" in
    "bionic")
        PHP_VER=7.2
        ;;
    "stretch")
        PHP_VER=7.0
        ;;
    "xenial")
        PHP_VER=7.0
        ;;
    *)
        echo 'Error: Could not figure out the distribution codename to install PHP. Exiting now!'
        exit 1
        ;;
esac

if ! grep -qw "$PHP_VER" /root/.envrc &> /dev/null ; then
    echo "export PHP_VER=$PHP_VER" >> /root/.envrc
fi

FPM_PHP_INI=/etc/php/${PHP_VER}/fpm/php.ini
CLI_PHP_INI=/etc/php/${PHP_VER}/cli/php.ini
POOL_FILE=/etc/php/${PHP_VER}/fpm/pool.d/${WP_SFTP_USER}.conf


### Please do not edit below this line ###

PHP_PACKAGES="php${PHP_VER}-fpm php${PHP_VER}-mysql php${PHP_VER}-gd php${PHP_VER}-cli php${PHP_VER}-xml php${PHP_VER}-mbstring php${PHP_VER}-soap php-curl"

if [ "$PHP_VER" = "7.0" ] ; then
    PHP_PACKAGES="$PHP_PACKAGES php${PHP_VER}-mcrypt"
fi

if [ "$PHP_VER" = "7.1" ] ; then
    PHP_PACKAGES="$PHP_PACKAGES php${PHP_VER}-mcrypt"
fi

if [ "$PHP_VER" = "7.2" ] ; then
    # todo: https://stackoverflow.com/questions/48275494/issue-in-installing-php7-2-mcrypt
    echo
    echo 'mycrypt is removed in PHP 7.2+.'
    echo 'Please check if any plugins or theme still use mcrypt by running...'
    echo 'cd ~/wproot/wp-content/'
    echo 'find ./ -type f -name '*.php' -print | xargs grep -inr mcrypt'
    echo
fi

apt-get install -qq ${PHP_PACKAGES} &> /dev/null

# let's take a backup of config before modifing them
BACKUP_PHP_DIR="/root/backups/etc-php-$(date +%F)"
if [ ! -d "$BACKUP_PHP_DIR" ]; then
    cp -a /etc $BACKUP_PHP_DIR
fi

echo 'Setting up memory limits for PHP...'


### ---------- php.ini modifications ---------- ###
# for https://github.com/pothi/wp-in-a-box/issues/35
sed -i -e '/^log_errors/ s/= On*/= Off/' $FPM_PHP_INI

# sed -i '/cgi.fix_pathinfo \?=/ s/;\? \?\(cgi.fix_pathinfo \?= \?\)1/\10/' $FPM_PHP_INI # as per the note number 6 at https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/
sed -i -e '/^max_execution_time/ s/=.*/= 300/' -e '/^max_input_time/ s/=.*/= 600/' $FPM_PHP_INI
sed -i -e '/^memory_limit/ s/=.*/= '$PHP_MEM_LIMIT'M/' $FPM_PHP_INI
sed -i -e '/^post_max_size/ s/=.*/= 64M/'      -e '/^upload_max_filesize/ s/=.*/= 64M/' $FPM_PHP_INI

# set max_input_vars to 5000 (from the default 1000)
sed -i '/max_input_vars/ s/;\? \?\(max_input_vars \?= \?\)[[:digit:]]\+/\15000/p' $FPM_PHP_INI

# Disable user.ini
sed -i -e '/^;user_ini.filename =$/ s/;//' $FPM_PHP_INI

# Setup timezone
sed -i -e 's/^;date\.timezone =$/date.timezone = "UTC"/' $FPM_PHP_INI


### ---------- pool-file modifications ---------- ###


mv /etc/php/${PHP_VER}/fpm/pool.d/www.conf $POOL_FILE &> /dev/null

echo 'Setting up the initial PHP user...'

# Change default user
sed -i -e 's/^\[www\]$/['$WP_SFTP_USER']/' $POOL_FILE
sed -i -e 's/www-data/'$WP_SFTP_USER'/' $POOL_FILE
# sed -i -e '/^\(user\|group\)/ s/=.*/= '$WP_SFTP_USER'/' $POOL_FILE
# sed -i -e '/^listen.\(owner\|group\)/ s/=.*/= '$WP_SFTP_USER'/' $POOL_FILE

sed -i -e '/^;listen.\(owner\|group\|mode\)/ s/^;//' $POOL_FILE
sed -i -e '/^listen.mode = / s/[0-9]\{4\}/0666/' $POOL_FILE

echo 'Setting up the port / socket for PHP...'

# Setup port / socket
# sed -i '/^listen =/ s/=.*/= 127.0.0.1:9006/' $POOL_FILE
sed -i "/^listen =/ s:=.*:= /var/lock/php-fpm-${PHP_VER}-${WP_SFTP_USER}:" $POOL_FILE
sed -i "s:/var/lock/php-fpm:/var/lock/php-fpm-${PHP_VER}-${WP_SFTP_USER}:" /etc/nginx/conf.d/lb.conf

sed -i -e 's/^pm = .*/pm = '$PM_METHOD'/' $POOL_FILE
sed -i '/^pm.max_children/ s/=.*/= '$PHP_MAX_CHILDREN'/' $POOL_FILE

echo 'Setting up the processes...'

#--- for dynamic PHP workers ---#
# PHP_MIN=$(expr $PHP_MAX_CHILDREN / 10)
# PHP_MAX=$(expr $PHP_MAX_CHILDREN / 2)
# PHP_DIFF=$(expr $PHP_MAX - $PHP_MIN)
# PHP_START=$(expr $PHP_MIN + $PHP_DIFF / 2)

# if [ "$PHP_MAX_CHILDREN" != '' ]; then
  # sed -i '/^pm = dynamic/ s/=.*/= static/' $POOL_FILE
  # sed -i '/^pm.max_children/ s/=.*/= '$PHP_MAX_CHILDREN'/' $POOL_FILE
  # sed -i '/^pm.start_servers/ s/=.*/= '$PHP_START'/' $POOL_FILE
  # sed -i '/^pm.min_spare_servers/ s/=.*/= '$PHP_MIN'/' $POOL_FILE
  # sed -i '/^pm.max_spare_servers/ s/=.*/= '$PHP_MAX'/' $POOL_FILE
# fi

sed -i '/^;catch_workers_output/ s/^;//' $POOL_FILE
sed -i '/^;pm.process_idle_timeout/ s/^;//' $POOL_FILE
sed -i '/^;pm.max_requests/ s/^;//' $POOL_FILE
sed -i '/^;pm.status_path/ s/^;//' $POOL_FILE
sed -i '/^;ping.path/ s/^;//' $POOL_FILE
sed -i '/^;ping.response/ s/^;//' $POOL_FILE

# slow log
PHP_SLOW_LOG_PATH="\/home\/${BASE_NAME}\/log\/slow-php.log"
sed -i '/^;slowlog/ s/^;//' $POOL_FILE
sed -i '/^slowlog/ s/=.*$/ = '$PHP_SLOW_LOG_PATH'/' $POOL_FILE
sed -i '/^;request_slowlog_timeout/ s/^;//' $POOL_FILE
sed -i '/^request_slowlog_timeout/ s/= .*$/= 60/' $POOL_FILE

# automatic restart upon random failure - directly from http://tweaked.io/guide/nginx/
FPMCONF="/etc/php/${PHP_VER}/fpm/php-fpm.conf"
sed -i '/^;emergency_restart_threshold/ s/^;//' $FPMCONF
sed -i '/^emergency_restart_threshold/ s/=.*$/= '$PHP_MIN'/' $FPMCONF
sed -i '/^;emergency_restart_interval/ s/^;//' $FPMCONF
sed -i '/^emergency_restart_interval/ s/=.*$/= 1m/' $FPMCONF
sed -i '/^;process_control_timeout/ s/^;//' $FPMCONF
sed -i '/^process_control_timeout/ s/=.*$/= 10s/' $FPMCONF

# tweaking opcache
echo Tweaking opcache...
cp $LOCAL_WPINABOX_REPO/config/php/mods-available/custom-opcache.ini /etc/php/${PHP_VER}/mods-available
ln -s /etc/php/${PHP_VER}/mods-available/custom-opcache.ini /etc/php/${PHP_VER}/fpm/conf.d/99-custom-opcache.ini &> /dev/null
ln -s /etc/php/${PHP_VER}/mods-available/custom-opcache.ini /etc/php/${PHP_VER}/cli/conf.d/99-custom-opcache.ini &> /dev/null

echo 'Restarting PHP daemon...'

/usr/sbin/php-fpm${PHP_VER} -t &> /dev/null && systemctl restart php${PHP_VER}-fpm &> /dev/null
if [ $? -ne 0 ]; then
    echo 'PHP-FPM failed to restart. Please check your configs!'; exit
else
    echo PHP-FPM successfully restarted.
fi


### ---------- other misc tasks ---------- ###

# restart php upon OOM or other failures
# ref: https://stackoverflow.com/a/45107512/1004587
sed -i '/^\[Service\]/!b;:a;n;/./ba;iRestart=on-failure' /lib/systemd/system/php${PHP_VER}-fpm.service
systemctl daemon-reload
if [ "$?" != 0 ]; then
    echo "Could not update /lib/systemd/system/php${PHP_VER}-fpm.service file!"
fi

echo 'Installing Composer for PHP...'
EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")

if [ "$EXPECTED_SIGNATURE" == "$ACTUAL_SIGNATURE" ]
then
    php composer-setup.php --quiet --install-dir=/usr/local/bin --filename=composer
fi
rm composer-setup.php &> /dev/null

# setup cron to self-update composer
crontab -l | grep -qw composer
if [ "$?" -ne "0" ]; then
    ( crontab -l; echo; echo "# auto-update composer - nightly" ) | crontab -
    ( crontab -l; echo '4   4   *   *   *   /usr/local/bin/composer self-update &> /dev/null' ) | crontab -
fi

echo 'All done with PHP-FPM!'
