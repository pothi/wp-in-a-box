#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

export DEBIAN_FRONTEND=noninteractive

echo 'Installing Nginx Server...'

# install prerequisites
# ref: https://nginx.org/en/linux_packages.html#Ubuntu
sudo apt-get -qq install curl gnupg2 ca-certificates lsb-release > /dev/null

if ! $(type 'codename' 2>/dev/null | grep -q 'function')
then
    codename() {
        lsb_release_cli=$(which lsb_release)
        local codename=""
        if [ ! -z $lsb_release_cli ]; then
            codename=$($lsb_release_cli -cs)
        else
            codename=$(cat /etc/os-release | awk -F = '/VERSION_CODENAME/{print $2}')
        fi
        echo "$codename"
    }
    codename=$(codename)
fi

# function to add the official Nginx.org repo
nginx_repo_add() {
    distro=$(awk -F= '/^ID=/{print $2}' /etc/os-release)

    if ! $(type 'codename' 2>/dev/null | grep -q 'function')
    then
        codename() {
            lsb_release_cli=$(which lsb_release)
            local codename=""
            if [ ! -z $lsb_release_cli ]; then
                codename=$($lsb_release_cli -cs)
            else
                codename=$(cat /etc/os-release | awk -F = '/VERSION_CODENAME/{print $2}')
            fi
            echo "$codename"
        }
        codename=$(codename)
    fi

    [ -f nginx_signing.key ] && rm nginx_signing.key
    curl -LSsO http://nginx.org/keys/nginx_signing.key
    check_result $? 'Nginx key could not be downloaded!'
    apt-key add nginx_signing.key &> /dev/null
    check_result $? 'Nginx key could not be added!'
    rm nginx_signing.key

    # for updated info, please see https://nginx.org/en/linux_packages.html#stable
    nginx_branch= # leave this empty to install stable version
    # or nginx_branch="mainline"

    if [ "$nginx_branch" == 'mainline' ]; then
        nginx_src_url="https://nginx.org/packages/mainline/${distro}/"
    else
        nginx_src_url="https://nginx.org/packages/${distro}/"
    fi

    echo "deb [arch=amd64] ${nginx_src_url} ${codename} nginx" > /etc/apt/sources.list.d/nginx.list
    echo "deb-src [arch=amd64] ${nginx_src_url} ${codename} nginx" >> /etc/apt/sources.list.d/nginx.list

    # finally update the local apt cache
    apt-get update -qq > /dev/null
}

case "$codename" in
    "stretch")
        nginx_repo_add
        ;;
    "focal")
        nginx_repo_add
        ;;
    "bionic")
        nginx_repo_add
        ;;
    "xenial")
        nginx_repo_add
        ;;
    "buster")
        nginx_repo_add
        ;;
    *)
        echo "Distro: $codename"
        echo 'Warning: Could not figure out the distribution codename. Continuing to install Nginx from the OS.'
        ;;
esac

apt-get install -qq nginx &> /dev/null
check_result $? 'Nginx: could not be installed.'

backup_dir="/root/backups/etc-nginx-$(date +%F)"

[ ! -d /root/backups ] && mkdir /root/backups

if [ ! -d "$backup_dir" ]; then
    cp -a /etc $backup_dir
fi

# deploy wordpress-nginx repo
if [ ! -d /root/git/wordpress-nginx ] ; then
    # git clone --quiet https://github.com/pothi/wordpress-nginx /root/git/wordpress-nginx
    # gitlab repo is more up-to-date
    git clone --quiet https://gitlab.com/pothi/wordpress-nginx /root/git/wordpress-nginx
else
    cd /root/git/wordpress-nginx && git pull --quiet origin master && cd - &> /dev/null
fi

cp -a /root/git/wordpress-nginx/* /etc/nginx/
cp /etc/nginx/nginx-sample.conf /etc/nginx/nginx.conf
[ ! -d /etc/nginx/sites-enabled ] && mkdir /etc/nginx/sites-enabled
ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf &> /dev/null

# create dhparam
if [ ! -f /etc/nginx/dhparam.pem ]; then
    $(which openssl) dhparam -dsaparam -out /etc/nginx/dhparam.pem 4096 &> /dev/null
    sed -i 's:^# \(ssl_dhparam /etc/nginx/dhparam.pem;\)$:\1:' /etc/nginx/conf.d/ssl-common.conf
fi

nginx -t &> /dev/null && systemctl restart nginx &> /dev/null
check_result $? 'Nginx: could not be restarted.'

# unattended-upgrades
unattended_file=/etc/apt/apt.conf.d/50unattended-upgrades
case "$codename" in
    "focal")
        if ! grep -q '"origin=nginx,codename=${distro_codename}";' $unattended_file ; then
            sed -i -e '/^Unattended-Upgrade::Origins-Pattern/ a "origin=nginx,codename=${distro_codename}";' $unattended_file
        fi
        ;;
    "buster")
        if ! grep -q '"origin=nginx,codename=${distro_codename}";' $unattended_file ; then
            sed -i -e '/^Unattended-Upgrade::Origins-Pattern/ a "origin=nginx,codename=${distro_codename}";' $unattended_file
        fi
        ;;
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

echo ... done installing up Nginx!
