#!/bin/bash

# TODO
# - Setup error log inside the user's home / log directory

# Variable/s
# WP_SFTP_USER=
# PHP_MAX_CHILDREN=
# MY_MEMCACHED_MEMORY

echo "Setting up PHP..."

# get the variables
source /root/.envrc

if [ -z "$WP_SFTP_USER" ]; then
    echo 'SFTP User is not found. Exiting prematurely!'; exit
fi

if [ -z "$PHP_MAX_CHILDREN" ]; then
    # let's be safe with a minmal value
    PHP_MAX_CHILDREN=4
fi

if [ -z "$PHP_MEM_LIMIT" ]; then
    # let's be safe with a minmal value
    PHP_MEM_LIMIT=128
fi

# LOG_FILE="/root/log/php-install.log"
# exec > >(tee -a ${LOG_FILE} )
# exec 2> >(tee -a ${LOG_FILE} >&2)

# php${PHP_VER}-mysqlnd package is not found in Ubuntu
PHP_VER=7.0
FPM_PHP_CLI=/etc/php/${PHP_VER}/fpm/php.ini
CLI_PHP_CLI=/etc/php/${PHP_VER}/cli/php.ini
POOL_FILE=/etc/php/${PHP_VER}/fpm/pool.d/${WP_SFTP_USER}.conf


### Please do not edit below this line ###


PHP_PACKAGES="php${PHP_VER}-fpm php${PHP_VER}-mysql php${PHP_VER}-gd php${PHP_VER}-mcrypt php${PHP_VER}-xml php${PHP_VER}-mbstring php${PHP_VER}-soap php-curl php-xdebug"

if apt-cache show php-redis &> /dev/null ; then
    PHP_PACKAGES=$(echo "$PHP_PACKAGES" 'php-redis')
else
    PHP_PACKAGES=$(echo "$PHP_PACKAGES" "php${PHP_VER}-redis")
fi

apt-get install -qq ${PHP_PACKAGES}

# let's take a backup of config before modifing them
BACKUP_PHP_DIR="/root/backups/etc-php-$(date +%F)"
if [ ! -d "$BACKUP_PHP_DIR" ]; then
    cp -a /etc $BACKUP_PHP_DIR
fi

echo; echo 'Setting up memory limits for PHP...'; echo;


### ---------- php.ini modifications ---------- ###
# for https://github.com/pothi/wp-in-a-box/issues/35
sed -i -e '/^log_errors/ s/= On*/= Off/' $FPM_PHP_CLI

# sed -i '/cgi.fix_pathinfo \?=/ s/;\? \?\(cgi.fix_pathinfo \?= \?\)1/\10/' $FPM_PHP_CLI # as per the note number 6 at https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/
sed -i -e '/^max_execution_time/ s/=.*/= 300/' -e '/^max_input_time/ s/=.*/= 600/' $FPM_PHP_CLI
sed -i -e '/^memory_limit/ s/=.*/= 256M/' $FPM_PHP_CLI
sed -i -e '/^post_max_size/ s/=.*/= 64M/'      -e '/^upload_max_filesize/ s/=.*/= 64M/' $FPM_PHP_CLI

# set max_input_vars to 5000 (from the default 1000)
sed -i '/max_input_vars/ s/;\? \?\(max_input_vars \?= \?\)[[:digit:]]\+/\15000/p' $FPM_PHP_CLI

# SESSION Handling
echo; echo 'Setting up sessions...'; echo;
sed -i -e '/^session.save_handler/ s/=.*/= redis/' $FPM_PHP_CLI
sed -i -e '/^;session.save_path/ s/.*/session.save_path = "127.0.0.1:6379"/' $FPM_PHP_CLI

# Disable user.ini
sed -i -e '/^;user_ini.filename =$/ s/;//' $FPM_PHP_CLI

# Setup timezone
sed -i -e 's/^;date\.timezone =$/date.timezone = "UTC"/' $FPM_PHP_CLI


### ---------- pool-file modifications ---------- ###


mv /etc/php/${PHP_VER}/fpm/pool.d/www.conf $POOL_FILE &> /dev/null

echo; echo 'Setting up the user'; echo;

# Change default user
sed -i -e 's/^\[www\]$/['$WP_SFTP_USER']/' $POOL_FILE
sed -i -e 's/www-data/'$WP_SFTP_USER'/' $POOL_FILE
# sed -i -e '/^\(user\|group\)/ s/=.*/= '$WP_SFTP_USER'/' $POOL_FILE
# sed -i -e '/^listen.\(owner\|group\)/ s/=.*/= '$WP_SFTP_USER'/' $POOL_FILE

sed -i -e '/^;listen.\(owner\|group\|mode\)/ s/^;//' $POOL_FILE
sed -i -e '/^listen.mode = / s/[0-9]\{4\}/0666/' $POOL_FILE

echo; echo 'Setting up the port / socket for PHP'; echo;

# Setup port / socket
# sed -i '/^listen =/ s/=.*/= 127.0.0.1:9006/' $POOL_FILE
sed -i "/^listen =/ s:=.*:= /var/lock/php-fpm-${PHP_VER}-${WP_SFTP_USER}:" $POOL_FILE
sed -i "s:/var/lock/php-fpm:/var/lock/php-fpm-${PHP_VER}-${WP_SFTP_USER}:" /etc/nginx/conf.d/lb.conf

sed -i -e 's/^pm = .*/pm = ondemand/' $POOL_FILE
sed -i '/^pm.max_children/ s/=.*/= '$PHP_MAX_CHILDREN'/' $POOL_FILE

echo; echo 'Setting up the processes...'; echo;

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

# automatic restart upon random failure - directly from http://tweaked.io/guide/nginx/
FPMCONF="/etc/php/${PHP_VER}/fpm/php-fpm.conf"
sed -i '/^;emergency_restart_threshold/ s/^;//' $FPMCONF
sed -i '/^emergency_restart_threshold/ s/=.*$/= '$PHP_MIN'/' $FPMCONF
sed -i '/^;emergency_restart_interval/ s/^;//' $FPMCONF
sed -i '/^emergency_restart_interval/ s/=.*$/= 1m/' $FPMCONF
sed -i '/^;process_control_timeout/ s/^;//' $FPMCONF
sed -i '/^process_control_timeout/ s/=.*$/= 10s/' $FPMCONF

echo; echo 'Restarting PHP daemon'; echo;

/usr/sbin/php-fpm${PHP_VER} -t && systemctl restart php${PHP_VER}-fpm
if [ "$?" != 0 ]; then
    echo 'PHP-FPM failed to restart. Please check your configs!'; exit
fi


### ---------- other misc tasks ---------- ###

# restart php upon OOM or other failures
sed -i '/^\[Service\]/!b;:a;n;/./ba;iRestart=on-failure' /lib/systemd/system/php7.0-fpm.service
systemctl daemon-reload
if [ "$?" != 0 ]; then
    echo 'Could not update /lib/systemd/system/php7.0-fpm.service file!'
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

echo; echo 'All done with PHP-FPM!'; echo;

