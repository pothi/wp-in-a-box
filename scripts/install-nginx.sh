#!/bin/bash

echo 'Installing Nginx Server'
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx-extras-dbg
LT_DIRECTORY="/root/backups/etc-nginx-$(date +%F)"
if [ ! -d "$LT_DIRECTORY" ]; then
	cp -a /etc $LT_DIRECTORY
fi
git clone https://github.com/pothi/wordpress-nginx ~/git/wordpress-nginx
cp -a ~/git/wordpress-nginx/{conf.d, errors, globals, sites-available} /etc/nginx/


