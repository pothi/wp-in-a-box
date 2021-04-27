#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

export DEBIAN_FRONTEND=noninteractive

# Defining return code check function
check_result() {
    if [ $1 -ne 0 ]; then
        echo "Error: $2"
        exit $1
    fi
}

function install_php_fpm {
    version=$1
    PACKAGES="php${version}-fpm \
        php${version}-mysql \
        php${version}-gd \
        php${version}-cli \
        php${version}-xml \
        php${version}-mbstring \
        php${version}-soap \
        php${version}-curl \
        php${version}-zip \
        php${version}-bcmath \
        php${version}-imagick"

    modules="common \
        json \
        opcache \
        readline \
        zip"

    if [ "$version" = "7.0" ] ; then
        apt-get -qq install "php${version}-mcrypt" &> /dev/null
    elif [ "$version" = "7.1" ] ; then
        apt-get -qq install "php${version}-mcrypt" &> /dev/null
    else
        echo
        echo Note on mcrypt
        echo --------------
        echo mycrypt is removed since PHP 7.2
        echo Please check if any plugins or theme still use mcrypt by running...
        echo 'find ~/wproot/wp-content/ -type f -name "*.php" -exec grep -inr mcrypt {} \;'
        echo
    fi

    apt-get install -qq ${PACKAGES} &> /dev/null
}

# Variable/s
# php_user
# PHP_MAX_CHILDREN
# MY_MEMCACHED_MEMORY
# PM_METHOD
# WP_ENVIRONMENT_TYPE # local, development, staging, production
# BASE_NAME

env_type=${WP_ENVIRONMENT_TYPE:-''}

#TODO:
# check for installation status of each package and then install individual packages.
# change fpm value in Nginx conf.d/lb.conf and vhost entries!

supplied_php_version=${PHP_VER:-""}

# get the variables
[ -f /root/.envrc ] && source /root/.envrc

PM_METHOD=ondemand

user_mem_limit=${PHP_MEM_LIMIT:-""}
if [ -z "$user_mem_limit" ]; then
    # let's be safe with a minmal value
    # echo 'Setting PHP memory limit to 256mb'
    user_mem_limit=256
fi

if [[ $env_type = "local" ]]; then
    sudo apt-get install software-properties-common
    sudo add-apt-repository --yes --update ppa:ondrej/php
    user_mem_limit=2048
fi

php_user=${DEV_USER:-""}
if [ -z "$php_user" ]; then
    echo 'DEV_USER environmental variable is not found.'
    echo 'If you use a different variable name for your developer, please update the script or /root/.envrc file and re-run.'
    echo 'Developer env variable is not found. Exiting prematurely!'; exit
fi

base_name=${BASE_NAME:-$php_user}

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

if [[ $env_type = "local" ]]; then
    PM_METHOD=ondemand
fi

# php${php_version}-mysqlnd package is not found in Ubuntu

codename=`lsb_release -c -s`
case "$codename" in
    "buster")
        system_php_version=7.3
        ;;
    "focal")
        system_php_version=7.4
        ;;
    "bionic")
        system_php_version=7.2
        ;;
    "stretch")
        system_php_version=7.0
        ;;
    "xenial")
        system_php_version=7.0
        ;;
    *)
        echo 'Error: Could not figure out the distribution codename to install PHP. Exiting now!'
        exit 1
        ;;
esac

# TODO: If PHP_VER is supplied via commandline, it isn't overriden here. Thus PHP_VER is always 7.4 or whatever is defined in /root/.envrc
php_version=${PHP_VER:-$system_php_version}
# temp hack for the above todo
[ ! -z $supplied_php_version ] && php_version=$supplied_php_version

if ! grep -qw "$PHP_VER" /root/.envrc &> /dev/null ; then
    echo "export PHP_VER=$php_version" >> /root/.envrc
fi

echo; echo "Installing PHP $php_version..."
echo -------------------------------------------------------------------------; echo

fpm_ini_file=/etc/php/${php_version}/fpm/php.ini
cli_ini_file=/etc/php/${php_version}/cli/php.ini
pool_file=/etc/php/${php_version}/fpm/pool.d/${php_user}.conf

### Please do not edit below this line ###

install_php_fpm $php_version

# let's take a backup of config before modifing them
datestamp="$(date +%F)"
[ ! -d "/root/backups/etc-php-$datestamp" ] && cp -a /etc /root/backups/etc-php-$datestamp

# echo 'Setting up memory limits for PHP...'

### ---------- php.ini modifications ---------- ###

# for https://github.com/pothi/wp-in-a-box/issues/35
echo 'Turning off logging of errors in php.ini...'
sed -i -e '/^log_errors/ s/= On*/= Off/' $fpm_ini_file

# sed -i '/cgi.fix_pathinfo \?=/ s/;\? \?\(cgi.fix_pathinfo \?= \?\)1/\10/' $fpm_ini_file # as per the note number 6 at https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/
# sed -i -e '/^max_execution_time/ s/=.*/= 300/' -e '/^max_input_time/ s/=.*/= 600/' $fpm_ini_file
echo "Configuring memory limit to ${user_mem_limit}MB"
sed -i -e '/^memory_limit/ s/=.*/= '$user_mem_limit'M/' $fpm_ini_file

user_max_filesize=${PHP_MAX_FILESIZE:-64}
echo "Configuring 'post_max_size' and 'upload_max_filesize' to ${user_max_filesize}MB..."
sed -i -e '/^post_max_size/ s/=.*/= '$user_max_filesize'M/' $fpm_ini_file
sed -i -e '/^upload_max_filesize/ s/=.*/= '$user_max_filesize'M/' $fpm_ini_file

# set max_input_vars to 5000 (from the default 1000)
user_max_input_vars=${PHP_MAX_INPUT_VARS:-5000}
echo "Configuring 'max_input_vars' to $user_max_input_vars (from the default 1000)..."
sed -i '/max_input_vars/ s/;\? \?\(max_input_vars \?= \?\)[[:digit:]]\+/\1'$user_max_input_vars'/' $fpm_ini_file

# Disable user.ini
echo "Disabling user.ini..."
sed -i -e '/^;user_ini.filename =$/ s/;//' $fpm_ini_file

# Setup timezone
user_timezone=${USER_TIMEZONE:-UTC}
echo "Configuring timezone to $user_timezone ..."
sed -i -e 's/^;date\.timezone =$/date.timezone = "'$user_timezone'"/' $fpm_ini_file

echo "Turning off logging for cli to prevent warning messaging while running wp-cli..."
# Turn off warning messages when running wp-cli
sed -i -e '/^log_errors/ s/=.*/= Off/' $cli_ini_file

# SESSION Handling
redis_pass=
[ -f /etc/redis/redis.conf ] && redis_pass=$(grep -w '^requirepass' /etc/redis/redis.conf | awk '{print $2}')
if [ ! -z $redis_pass ] ; then
    echo 'Setting up sessions with redis...';
    sed -i -e '/^session.save_handler/ s/=.*/= redis/' $fpm_ini_file
    sed -i -e '/^session.save_path/ s/.*/session.save_path = "tcp:\/\/127.0.0.1:6379?auth='$redis_pass'"/' $fpm_ini_file
fi

### ---------- pool-file modifications ---------- ###

[ ! -f $pool_file ] && mv /etc/php/${php_version}/fpm/pool.d/www.conf $pool_file

# echo 'Setting up the initial PHP user...'

# Change default user
sed -i -e 's/^\[www\]$/['$php_user']/' $pool_file
sed -i -e 's/www-data/'$php_user'/' $pool_file
# sed -i -e '/^\(user\|group\)/ s/=.*/= '$php_user'/' $pool_file
# sed -i -e '/^listen.\(owner\|group\)/ s/=.*/= '$php_user'/' $pool_file

sed -i -e '/^;listen.\(owner\|group\|mode\)/ s/^;//' $pool_file
sed -i -e '/^listen.mode = / s/[0-9]\{4\}/0666/' $pool_file

# echo 'Setting up the port / socket for PHP...'

# Setup port / socket
# sed -i '/^listen =/ s/=.*/= 127.0.0.1:9006/' $pool_file
php_version_short=$(echo $php_version | sed 's/\.//')
sed -i "/^listen =/ s:=.*:= /var/lock/php-fpm-${php_version_short}-${php_user}:" $pool_file
sed -i "s:/var/lock/php-fpm.*;:/var/lock/php-fpm-${php_version_short}-${php_user};:" /etc/nginx/conf.d/lb.conf

if [ ! -f /etc/nginx/conf.d/fpm-${php_version_short}.conf ]; then
    echo "upstream fpm${php_version_short} { server unix:/var/lock/php-fpm-${php_version_short}-dev; }" > /etc/nginx/conf.d/fpm-${php_version_short}.conf
fi

sed -i -e 's/^pm = .*/pm = '$PM_METHOD'/' $pool_file
sed -i '/^pm.max_children/ s/=.*/= '$max_children'/' $pool_file

# echo 'Setting up the processes...'

#--- for dynamic PHP workers ---#
PHP_MIN=$(expr $max_children / 10)
# PHP_MAX=$(expr $max_children / 2)
# PHP_DIFF=$(expr $PHP_MAX - $PHP_MIN)
# PHP_START=$(expr $PHP_MIN + $PHP_DIFF / 2)

# if [ "$max_children" != '' ]; then
  # sed -i '/^pm = dynamic/ s/=.*/= static/' $pool_file
  # sed -i '/^pm.max_children/ s/=.*/= '$max_children'/' $pool_file
  # sed -i '/^pm.start_servers/ s/=.*/= '$PHP_START'/' $pool_file
  # sed -i '/^pm.min_spare_servers/ s/=.*/= '$PHP_MIN'/' $pool_file
  # sed -i '/^pm.max_spare_servers/ s/=.*/= '$PHP_MAX'/' $pool_file
# fi

sed -i '/^;catch_workers_output/ s/^;//' $pool_file
sed -i '/^;pm.process_idle_timeout/ s/^;//' $pool_file
sed -i '/^;pm.max_requests/ s/^;//' $pool_file
sed -i '/^;pm.status_path/ s/^;//' $pool_file
sed -i '/^;ping.path/ s/^;//' $pool_file
sed -i '/^;ping.response/ s/^;//' $pool_file

# slow log
PHP_SLOW_LOG_PATH="\/home\/${base_name}\/log\/slow-php.log"
sed -i '/^;slowlog/ s/^;//' $pool_file
sed -i '/^slowlog/ s/=.*$/ = '$PHP_SLOW_LOG_PATH'/' $pool_file
sed -i '/^;request_slowlog_timeout/ s/^;//' $pool_file
sed -i '/^request_slowlog_timeout/ s/= .*$/= 60/' $pool_file

# automatic restart upon random failure - directly from http://tweaked.io/guide/nginx/
FPMCONF="/etc/php/${php_version}/fpm/php-fpm.conf"
sed -i '/^;emergency_restart_threshold/ s/^;//' $FPMCONF
sed -i '/^emergency_restart_threshold/ s/=.*$/= '$PHP_MIN'/' $FPMCONF
sed -i '/^;emergency_restart_interval/ s/^;//' $FPMCONF
sed -i '/^emergency_restart_interval/ s/=.*$/= 1m/' $FPMCONF
sed -i '/^;process_control_timeout/ s/^;//' $FPMCONF
sed -i '/^process_control_timeout/ s/=.*$/= 10s/' $FPMCONF

# tweaking opcache
# echo Tweaking opcache...
local_wp_in_a_box_repo=/root/git/wp-in-a-box
if [ -f $local_wp_in_a_box_repo/config/php/mods-available/custom-opcache.ini ]; then
    cp $local_wp_in_a_box_repo/config/php/mods-available/custom-opcache.ini /etc/php/${php_version}/mods-available
    ln -s /etc/php/${php_version}/mods-available/custom-opcache.ini /etc/php/${php_version}/fpm/conf.d/99-custom-opcache.ini &> /dev/null
    ln -s /etc/php/${php_version}/mods-available/custom-opcache.ini /etc/php/${php_version}/cli/conf.d/99-custom-opcache.ini &> /dev/null
fi

echo 'Restarting PHP daemon...'

/usr/sbin/php-fpm${php_version} -t &> /dev/null && systemctl restart php${php_version}-fpm &> /dev/null
if [ $? -ne 0 ]; then
    echo 'PHP-FPM failed to restart. Please check your configs!'; exit
else
    printf '\t\t\t%s\n' "... PHP-FPM was successfully restarted."
fi

echo 'Restarting Nginx...'

/usr/sbin/nginx -t &> /dev/null && systemctl restart nginx &> /dev/null
if [ $? -ne 0 ]; then
    echo 'Nginx failed to restart. Please check your configs! Exiting now!'; exit
else
    # echo ... Nginx was successfully restarted.
    printf '\t\t\t%s\n' "... Nginx was successfully restarted."
fi

### ---------- other misc tasks ---------- ###

# restart php upon OOM or other failures
# ref: https://stackoverflow.com/a/45107512/1004587
sed -i '/^\[Service\]/!b;:a;n;/./ba;iRestart=on-failure' /lib/systemd/system/php${php_version}-fpm.service
systemctl daemon-reload
check_result $? "Could not update /lib/systemd/system/php${php_version}-fpm.service file!"

echo; echo -------------------------------------------------------------------------
echo "All done with PHP $php_version!"
echo
