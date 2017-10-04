#!/bin/bash

# Version: 1.2

# Changelog
# 2017-02-13 - version 1.2
#   moved files around
#   split bootstrap file into smaller segments to make it easier to replace a component (ex: postfix / exim)
# 2017-02-12 - version 1.1
#   awscli installation is simplified now
# 2017-02-12 - version 1.0
#   Tmux is not going to be installed and its config will be removed in a future version - just use screen going forward

# to be run as root, probably as a user-script just after a server is installed

# as root
# if [[ $USER != "root" ]]; then
# echo "This script must be run as root"
# exit 1
# fi

# TODO - change the default repo, if needed - mostly not needed on most hosts

# create some useful directories - create them on demand
mkdir -p /root/{backups,git,log,scripts} &> /dev/null
LOG_FILE=/root/log/wp-in-a-box.log
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

# take a backup
LT_DIRECTORY="/root/backups/etc-before-wp-in-a-box-$(date +%F)"
if [ ! -d "$LT_DIRECTORY" ]; then
    echo -n 'Taking an initial backup...'
    mkdir $LT_DIRECTORY
    cp -a /etc $LT_DIRECTORY
    echo 'done.'
fi

apt-get update -y

LOCAL_WPINABOX_REPO=/root/git/wp-in-a-box

if [ -d $LOCAL_WPINABOX_REPO ] ; then
    cd $LOCAL_WPINABOX_REPO
    git pull -q origin master
    git pull -q --recurse-submodules
    cd - &> /dev/null
else
    DEBIAN_FRONTEND=noninteractive apt-get -q -y install git 
    git clone -q --recursive https://github.com/pothi/wp-in-a-box $LOCAL_WPINABOX_REPO
fi

# create swap at first
source $LOCAL_WPINABOX_REPO/scripts/swap.sh

# install dependencies
echo -n 'Updating the server...'
DEBIAN_FRONTEND=noninteractive apt-get -q -y upgrade
DEBIAN_FRONTEND=noninteractive apt-get -q -y dist-upgrade
apt-get -q -y autoremove
echo "done."

source $LOCAL_WPINABOX_REPO/scripts/base-installation.sh
source $LOCAL_WPINABOX_REPO/scripts/setup-linux-tweaks.sh
source $LOCAL_WPINABOX_REPO/scripts/install-nginx.sh
source $LOCAL_WPINABOX_REPO/scripts/install-mysql.sh
source $LOCAL_WPINABOX_REPO/scripts/create-sftp-user.sh
source $LOCAL_WPINABOX_REPO/scripts/install-php7.sh

# the following can be executed at any order
# source $LOCAL_WPINABOX_REPO/scripts/install-firewall.sh
source $LOCAL_WPINABOX_REPO/scripts/emergency-user-creation.sh

# post-install steps
codename=`lsb_release -c -s`
case "$codename" in
    "stretch")
        source $LOCAL_WPINABOX_REPO/scripts/post-install-stretch.sh
        ;;
    "xenial")
        source $LOCAL_WPINABOX_REPO/scripts/post-install-xenial.sh
        ;;
    *)
        echo 'Warning: Could not figure out the distribution codename. Skipping post-install steps!'
        ;;
esac

# take a backup, after doing everything
echo -n 'Taking a final backup'
LT_DIRECTORY="/root/backups/etc-after-wp-in-a-box-$(date +%F)"
if [ ! -d "$LT_DIRECTORY" ]; then
    cp -a /etc $LT_DIRECTORY
fi
echo "done."

# logout and then login to see the changes
echo 'All done.'

echo '-----------------------------------'
echo "SFTP username is $WP_SFTP_USER"
echo "SFTP password is $WP_SFTP_PASS"
echo '-----------------------------------'
echo "Emergency username is $ICE_USER"
echo "Emergency password is $ICE_PASS"
echo '-----------------------------------'

echo 'Please make a note of these somewhere safe'
echo 'Also please test if things are okay!'
# TODO
# run automated tests
# swap
# PHP is setup correctly
# Nginx is setup correctly
# PhpMyAdmin

echo 'You may reboot only once to apply certain updates (hint: kernel updates)!'
echo
