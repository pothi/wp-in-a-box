#!/bin/bash

# TODO: if client.sh isn't run earlier, make sure you do not modify the default vhost config
# TODO: if this script run multiple times, it shouldn't create any errors

# Variable/s
# MY_SFTP_USER=
# MY_PHP_MAX_CHILDREN=
# MY_MEMCACHED_MEMORY

# get the variables
source /root/.my.exports

LOG_FILE="/root/log/php-install.log"
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

# lets check if our fav mariadb-server exists
SQL_SERVER=mariadb-server
if ! apt-cache show mariadb-server &> /dev/null ; then SQL_SERVER=mysql-server ; fi

DEBIAN_FRONTEND=noninteractive apt-get install ${SQL_SERVER} -y

# Memcached server
# if ! apt-cache show memcached &> /dev/null ; then echo 'Memcached server not found!' ; fi
# apt-get install memcached -y
# cp /etc/memcached.conf /root/backups/memcached.conf-$(date +%F)
# sed -i '/^.m / s/[0-9]\+/'$MY_MEMCACHED_MEMORY'/' /etc/memcached.conf
# systemctl restart memcached

# Redis server
if ! apt-cache show redis-server &> /dev/null ; then echo 'Redis server not found!'; exit ; fi
apt-get install redis-server -y

# php${PHP_VER}-mysqlnd package is not found in Ubuntu
PHP_VER=7.0
PHP_PACKAGES="php${PHP_VER}-fpm php${PHP_VER}-mysql php${PHP_VER}-gd php${PHP_VER}-mcrypt php${PHP_VER}-xml php${PHP_VER}-mbstring php-curl php-xdebug"

# at times the version number is not included for memcache(d) extension; let's check it
# if apt-cache show php-memcached &> /dev/null ; then
#     PHP_PACKAGES=$(echo "$PHP_PACKAGES" 'php-memcached')
# else
#     PHP_PACKAGES=$(echo "$PHP_PACKAGES" "php${PHP_VER}-memcached")
# fi

# if apt-cache show php-memcache &> /dev/null ; then
#     PHP_PACKAGES=$(echo "$PHP_PACKAGES" 'php-memcache')
# else
#     PHP_PACKAGES=$(echo "$PHP_PACKAGES" "php${PHP_VER}-memcache")
# fi

if apt-cache show php-redis &> /dev/null ; then
    PHP_PACKAGES=$(echo "$PHP_PACKAGES" 'php-redis')
else
    PHP_PACKAGES=$(echo "$PHP_PACKAGES" "php${PHP_VER}-redis")
fi

apt-get install -y ${PHP_PACKAGES}

# let's take a backup of config before modifing them
BACKUP_PHP_DIR="/root/backups/etc-php-$(date +%F)"
if [ ! -d "$BACKUP_PHP_DIR" ]; then
	cp -a /etc $BACKUP_PHP_DIR
fi

echo; echo 'Setting up memory limits'; echo;

PHP_INI=/etc/php/${PHP_VER}/fpm/php.ini
sed -i '/cgi.fix_pathinfo=/ s/;\(cgi.fix_pathinfo=\)1/\10/' $PHP_INI
sed -i -e '/^max_execution_time/ s/=.*/= 300/' -e '/^max_input_time/ s/=.*/= 600/' $PHP_INI
sed -i -e '/^memory_limit/ s/=.*/= 256M/' $PHP_INI
sed -i -e '/^post_max_size/ s/=.*/= 64M/'      -e '/^upload_max_filesize/ s/=.*/= 64M/' $PHP_INI


echo; echo 'Setting up sessions...'; echo;

# SESSION Handling
sed -i -e '/^session.save_handler/ s/=.*/= redis/' $PHP_INI
sed -i -e '/^;session.save_path/ s/.*/session.save_path = "127.0.0.1:6379"/' $PHP_INI
# sed -i -e '/^session.save_handler/ s/=.*/= memcached/' $PHP_INI
# sed -i -e '/^;session.save_path/ s/.*/session.save_path = "127.0.0.1:11211"/' $PHP_INI

# Disable user.ini
sed -i -e '/^;user_ini.filename =$/ s/;//' $PHP_INI

POOLPHP=/etc/php/${PHP_VER}/fpm/pool.d/${MY_SFTP_USER}.conf
mv /etc/php/${PHP_VER}/fpm/pool.d/www.conf $POOLPHP

echo; echo 'Setting up the user'; echo;

# Change default user
sed -i -e 's/^\[www\]$/['$MY_SFTP_USER']/' $POOLPHP
sed -i -e '/^\(user\|group\)/ s/=.*/= '$MY_SFTP_USER'/' $POOLPHP
sed -i -e '/^;listen.\(owner\|group\|mode\)/ s/^;//' $POOLPHP
sed -i -e '/^listen.mode = / s/[0-9]\{4\}/0666/' $POOLPHP
sed -i -e '/^listen.\(owner\|group\)/ s/=.*/= '$MY_SFTP_USER'/' $POOLPHP

echo; echo 'Setting up the port / socket for PHP'; echo;

# Setup port / socket
sed -i '/^listen =/ s/=.*/= 127.0.0.1:9006/' $POOLPHP
# sed -i '/^listen =/ s:=.*:= /var/lock/php-fpm:' $POOLPHP

echo; echo 'Setting up the processes...'; echo;

PHP_MIN=$(expr $MY_PHP_MAX_CHILDREN / 10)
PHP_MAX=$(expr $MY_PHP_MAX_CHILDREN / 2)
PHP_DIFF=$(expr $PHP_MAX - $PHP_MIN)
PHP_START=$(expr $PHP_MIN + $PHP_DIFF / 2)

if [ "$MY_PHP_MAX_CHILDREN" != '' ]; then
  # sed -i '/^pm = dynamic/ s/=.*/= static/' $POOLPHP
  sed -i '/^pm.max_children/ s/=.*/= '$MY_PHP_MAX_CHILDREN'/' $POOLPHP
  sed -i '/^pm.start_servers/ s/=.*/= '$PHP_START'/' $POOLPHP
  sed -i '/^pm.min_spare_servers/ s/=.*/= '$PHP_MIN'/' $POOLPHP
  sed -i '/^pm.max_spare_servers/ s/=.*/= '$PHP_MAX'/' $POOLPHP
fi

sed -i '/^;catch_workers_output/ s/^;//' $POOLPHP
sed -i '/^;pm.process_idle_timeout/ s/^;//' $POOLPHP
sed -i '/^;pm.max_requests/ s/^;//' $POOLPHP
sed -i '/^;pm.status_path/ s/^;//' $POOLPHP
sed -i '/^;ping.path/ s/^;//' $POOLPHP
sed -i '/^;ping.response/ s/^;//' $POOLPHP

# automatic restart upon random failure - directly from http://tweaked.io/guide/nginx/
FPMCONF="/etc/php/${PHP_VER}/fpm/php-fpm.conf"
sed -i '/^;emergency_restart_threshold/ s/^;//' $FPMCONF
sed -i '/^emergency_restart_threshold/ s/=.*$/= '$PHP_MIN'/' $FPMCONF
sed -i '/^;emergency_restart_interval/ s/^;//' $FPMCONF
sed -i '/^emergency_restart_interval/ s/=.*$/= 1m/' $FPMCONF
sed -i '/^;process_control_timeout/ s/^;//' $FPMCONF
sed -i '/^process_control_timeout/ s/=.*$/= 10s/' $FPMCONF

echo; echo 'Restarting PHP daemon'; echo;

systemctl restart php${PHP_VER}-fpm
if [ "$?" != 0 ]; then
	service php${PHP_VER}-fpm restart
fi

echo; echo 'All done; Good luck'; echo;
