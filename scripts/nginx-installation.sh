#!/bin/bash

echo 'Installing Nginx Server...'

rm nginx_signing.key &> /dev/null
curl -LSsO http://nginx.org/keys/nginx_signing.key
apt-key add nginx_signing.key &> /dev/null
if [ "$?" -ne "0" ]; then
    echo 'Nginx key could not be added!'
fi
rm nginx_signing.key

DISTRO=$(gawk -F= '/^ID=/{print $2}' /etc/os-release)
CODENAME=$(lsb_release -c -s)

# for updated info, please see https://nginx.org/en/linux_packages.html#stable
NGX_BRANCH= # leave this empty to install stable version
# or NGX_BRANCH="mainline"

if [ "$NGX_BRANCH" == 'mainline' ]; then
    nginx_src_url="https://nginx.org/packages/mainline/${DISTRO}/"
else
    nginx_src_url="https://nginx.org/packages/${DISTRO}/"
fi

echo "deb ${nginx_src_url} ${CODENAME} nginx" > /etc/apt/sources.list.d/nginx.list
echo "deb-src ${nginx_src_url} ${CODENAME} nginx" >> /etc/apt/sources.list.d/nginx.list

apt-get update -qq

DEBIAN_FRONTEND=noninteractive apt-get install -qq nginx &> /dev/null
LT_DIRECTORY="/root/backups/etc-nginx-$(date +%F)"
if [ ! -d "$LT_DIRECTORY" ]; then
    cp -a /etc $LT_DIRECTORY
fi

# no longer necessary
# sed -i 's/worker_processes.*/worker_processes auto;/' /etc/nginx/nginx.conf
# sed -i 's/#.\?gzip/gzip/' /etc/nginx/nginx.conf

# deploy wordpress-nginx repo
if [ -d /root/git/wordpress-nginx ] ; then
    cd /root/git/wordpress-nginx && git pull origin master && cd - &> /dev/null
else
    # git clone https://github.com/pothi/wordpress-nginx /root/git/wordpress-nginx
    # switch to gitlab repo
    git clone --quiet https://gitlab.com/pothi/wordpress-nginx /root/git/wordpress-nginx
fi

cp -a /root/git/wordpress-nginx/* /etc/nginx/
cp /etc/nginx/nginx-sample.conf /etc/nginx/nginx.conf
mkdir /etc/nginx/sites-enabled &> /dev/null
ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf &> /dev/null

nginx -t && systemctl restart nginx &> /dev/null
if [ $? -ne 0 ] ; then
    echo 'Nginx: could not be restarted'
fi

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
