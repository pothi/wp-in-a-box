#!/bin/bash

# post-install script for Debian

apt-get install certbot -t stretch-backports -q -y
if [ "$?" -ne "0" ]; then
    echo 'deb http://deb.debian.org/debian stretch-backports main' > /etc/apt/sources.list.d/backports.list
    apt-get update -qq
    apt-get install certbot -t stretch-backports -q -y
    if [ "$?" -ne "0" ]; then
        echo 'Something went wrong while installing Certbot using backports. Please check the logs.'
    fi
fi
