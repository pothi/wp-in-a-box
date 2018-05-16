#!/bin/bash

source ~/.envrc

# variables
redis_maxmemory_policy='allkeys-lru'
redis_conf_file='/etc/redis/redis.conf'
redis_sysctl_file='/etc/sysctl.d/60-redis-local.conf'
redis_pass=$(pwgen -cns 20 1)
# PHP_VER from php-installation.php

echo -n 'Installing redis... '
apt-get install -qq redis &> /dev/null
echo 'done.'

if apt-cache show php-redis &> /dev/null ; then
    redis_php_package=php-redis
else
    redis_php_package="php${PHP_VER}-redis"
fi

echo -n 'Installing redis for PHP... '
apt-get install -qq ${redis_php_package} &> /dev/null
echo 'done.'

echo Tweaking redis cache...

# calculate memory to use for redis
sys_memory=$(free -m | grep -oP '\d+' | head -n 1)
redis_memory=$(($sys_memory / 32))
sed -i -e 's/^#\? \?\(maxmemory \).*$/\1'$redis_memory'm/' $redis_conf_file

# change the settings for maxmemory-policy
sed -i -e 's/^#\? \?\(maxmemory\-policy\).*$/\1 '$redis_maxmemory_policy'/' $redis_conf_file

# set password
sed -i -e 's/^#\? \?\(requirepass\).*$/\1 '$redis_pass'/' $redis_conf_file

# create / overwrite and append our custom values in it
printf "vm.overcommit_memory = 1\n" > $redis_sysctl_file &> /dev/null
printf "net.core.somaxconn = 1024\n" >> $redis_sysctl_file &> /dev/null

# Load settings from the redis sysctl file
sysctl -p $redis_sysctl_file

# restart redis
/bin/systemctl restart redis-server

echo '... done tweaking redis cache.'

# SESSION Handling
echo 'Setting up PHP sessions to use redis... '
sed -i -e '/^session.save_handler/ s/=.*/= redis/' $FPM_PHP_INI
sed -i -e '/^;session.save_path/ s/.*/session.save_path = "127.0.0.1:6379?auth='$redis_pass'"/' $FPM_PHP_INI

/usr/sbin/php-fpm${PHP_VER} -t &> /dev/null && systemctl restart php${PHP_VER}-fpm &> /dev/null
if [ "$?" != 0 ]; then
    echo 'PHP-FPM failed to restart. Please check your configs!'; exit
fi

echo '... done setting up PHP sessions to use redis!'
