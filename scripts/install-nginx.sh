#!/bin/bash

echo 'Installing Nginx Server...'

# no longer needed; it's part of apt
# apt-get install -y apt-key

curl -LSsO http://nginx.org/keys/nginx_signing.key
apt-key add nginx_signing.key
rm nginx_signing.key

DISTRO=$(gawk -F= '/^ID=/{print $2}' /etc/os-release)
CODENAME=$(lsb_release -c -s)

# for updated info, please see https://nginx.org/en/linux_packages.html#stable
NGX_BRANCH= # leave this empty to install stable version
# or NGX_BRANCH="mainline/"

echo "deb https://nginx.org/packages/${NGX_BRANCH}${DISTRO}/ ${CODENAME} nginx" > /etc/apt/sources.list.d/nginx.list
echo "deb-src https://nginx.org/packages/${NGX_BRANCH}${DISTRO}/ ${CODENAME} nginx" >> /etc/apt/sources.list.d/nginx.list

apt-get update -qq

DEBIAN_FRONTEND=noninteractive apt-get install -qq nginx
LT_DIRECTORY="/root/backups/etc-nginx-$(date +%F)"
if [ ! -d "$LT_DIRECTORY" ]; then
    cp -a /etc $LT_DIRECTORY
fi

sed -i 's/worker_processes.*/worker_processes auto;/' /etc/nginx/nginx.conf
sed -i 's/#.\?gzip/gzip/' /etc/nginx/nginx.conf

if [ -d /root/git/wordpress-nginx ] ; then
    cd /root/git/wordpress-nginx && git pull origin master && cd - &> /dev/null
else
    git clone https://github.com/pothi/wordpress-nginx /root/git/wordpress-nginx
fi

cp -a /root/git/wordpress-nginx/* /etc/nginx/

# unattended-upgrades
unattended_file=/etc/apt/apt.conf.d/50unattended-upgrades
if ! grep -q '"origin=nginx,codename=stretch";' $unattended_file ; then
    sed -i -e '/^Unattended-Upgrade::Origins-Pattern/ a "origin=nginx,codename=stretch";' $unattended_file
fi

echo "Done setting up Nginx!"
