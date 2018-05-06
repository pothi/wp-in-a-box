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

DEBIAN_FRONTEND=noninteractive apt-get install -qq nginx &> /dev/null
LT_DIRECTORY="/root/backups/etc-nginx-$(date +%F)"
if [ ! -d "$LT_DIRECTORY" ]; then
    cp -a /etc $LT_DIRECTORY
fi

sed -i 's/worker_processes.*/worker_processes auto;/' /etc/nginx/nginx.conf
sed -i 's/#.\?gzip/gzip/' /etc/nginx/nginx.conf

# deploy wordpress-nginx repo
if [ -d /root/git/wordpress-nginx ] ; then
    cd /root/git/wordpress-nginx && git pull origin master && cd - &> /dev/null
else
    # git clone https://github.com/pothi/wordpress-nginx /root/git/wordpress-nginx
    # switch to gitlab repo
    git clone https://gitlab.com/pothi/wordpress-nginx /root/git/wordpress-nginx
fi

cp -a /root/git/wordpress-nginx/* /etc/nginx/
mkdir /etc/nginx/sites-enabled &> /dev/null
cp /etc/nginx/nginx.conf /etc/nginx/ori-nginx.conf
cp /etc/nginx/nginx-sample.conf /etc/nginx/nginx.conf

# unattended-upgrades
unattended_file=/etc/apt/apt.conf.d/50unattended-upgrades
codename=`lsb_release -c -s`
case "$codename" in
    "stretch")
        if ! grep -q '"origin=nginx,codename=${distro_codename}";' $unattended_file ; then
            sed -i -e '/^Unattended-Upgrade::Origins-Pattern/ a "origin=nginx,codename=${distro_codename}";' $unattended_file
        fi
        ;;
    "xenial")
        if ! grep -q '"nginx:${distro_codename}";' $unattended_file ; then
            sed -i -e '/^Unattended-Upgrade::Allowed-Origins/ a "nginx:${distro_codename}";' $unattended_file
        fi
        ;;
    "bionic")
        if ! grep -q '"nginx:${distro_codename}";' $unattended_file ; then
            sed -i -e '/^Unattended-Upgrade::Allowed-Origins/ a "nginx:${distro_codename}";' $unattended_file
        fi
        ;;
    *)
        echo 'Warning: Could not figure out the distribution codename. Skipping unattended upgrade for nginx!'
        ;;
esac

echo "Done setting up Nginx!"
