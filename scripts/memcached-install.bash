#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

export DEBIAN_FRONTEND=noninteractive

# what's done here.
# install php{ver}-memcached and php{ver}-memcache packages
# update PHP session handling to memcache
# configure memory for memcached server

# Post install steps
#   - install https://wordpress.org/plugins/memcached/#installation
#   - (or) download https://plugins.svn.wordpress.org/memcached/trunk/object-cache.php into wp-content dir.
#   - configure WP_CACHE_KEY_SALT using the command... wp config set WP_CACHE_KEY_SALT $(openssl rand -base64 32)

# variables

echo "Setting up memcached..."

if [ "$MEMCACHED_MEM_LIMIT" == "" ]; then
    MEMCACHED_MEM_LIMIT=64
fi

PHP_VER=8.3
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
     PHP_PACKAGES=$(echo "$PHP_PACKAGES" "php${PHP_VER}-memcached")
# fi

# if apt-cache show php-memcache &> /dev/null ; then
#     PHP_PACKAGES=$(echo "$PHP_PACKAGES" 'php-memcache')
# else
     PHP_PACKAGES=$(echo "$PHP_PACKAGES" "php${PHP_VER}-memcache")
# fi

apt-get -qq install ${PHP_PACKAGES}

# SESSION Handling
sed -i -e '/^session.save_handler/ s/=.*/= memcached/' $PHP_INI
sed -i -e '/^;session.save_path/ s/.*/session.save_path = "127.0.0.1:11211"/' $PHP_INI

systemctl restart php${PHP_VER}-fpm
if [ "$?" != 0 ]; then
    echo 'PHP-FPM failed to restart after integrating memcached. Please check your configs!'
fi

echo "... done setting up memcached!"
