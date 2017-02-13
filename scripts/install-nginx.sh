#!/bin/bash

echo 'Installing Nginx Server'
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx-extras-dbg
LT_DIRECTORY="/root/backups/etc-nginx-$(date +%F)"
if [ ! -d "$LT_DIRECTORY" ]; then
	cp -a /etc $LT_DIRECTORY
fi

if [ -d /root/git/wordpress-nginx ] ; then
    cd /root/git/wordpress-nginx && git pull origin master && cd - &> /dev/null
else
    git clone https://github.com/pothi/wordpress-nginx /root/git/wordpress-nginx
fi

cp -a /root/git/wordpress-nginx/{conf.d,errors,globals,sites-available} /etc/nginx/


