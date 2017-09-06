#!/bin/bash

echo 'Installing Nginx Server'

# no longer needed; it's part of apt
# apt-get install -y apt-key

curl http://nginx.org/keys/nginx_signing.key | apt-key add -
rm nginx_signing.key &> /dev/null

DISTRO=$(gawk -F= '/^ID=/{print $2}' /etc/os-release)
CODENAME=$(lsb_release -c -s)

# for updated info, please see https://nginx.org/en/linux_packages.html#stable
NGX_BRANCH= # leave this empty to install stable version
# or NGX_BRANCH="mainline/"

echo "deb https://nginx.org/packages/${NGX_BRANCH}${DISTRO}/ ${CODENAME} nginx" > /etc/apt/sources.list.d/nginx.list
echo "deb-src https://nginx.org/packages/${NGX_BRANCH}${DISTRO}/ ${CODENAME} nginx" >> /etc/apt/sources.list.d/nginx.list

apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
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


