#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

echo "Setting up memcached..."

if [ "$MEMCACHED_MEM_LIMIT" == "" ]; then
    MEMCACHED_MEM_LIMIT=64
fi

PHP_VER=7.0
PHP_INI=/etc/php/${PHP_VER}/fpm/php.ini

# Memcached server
if ! apt-cache show memcached &> /dev/null ; then echo 'Memcached server not found!' ; fi
apt-get install memcached -y
cp /etc/memcached.conf /root/backups/memcached.conf-$(date +%F)
sed -i '/^.m / s/[0-9]\+/'$MEMCACHED_MEM_LIMIT'/' /etc/memcached.conf
systemctl restart memcached

PHP_PACKAGES=''
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

apt-get install -y ${PHP_PACKAGES}

# SESSION Handling
sed -i -e '/^session.save_handler/ s/=.*/= memcached/' $PHP_INI
sed -i -e '/^;session.save_path/ s/.*/session.save_path = "127.0.0.1:11211"/' $PHP_INI

systemctl restart php${PHP_VER}-fpm
if [ "$?" != 0 ]; then
    echo 'PHP-FPM failed to restart after integrating memcached. Please check your configs!'
fi

echo "... done setting up memcached!"
