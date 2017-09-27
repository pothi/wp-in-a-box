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

# take a backup
mkdir -p /root/{backups,git,log,others,scripts,src,tmp,bin} &> /dev/null

LOG_FILE=/root/log/wp-in-a-box.log
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

# take a backup
echo 'Taking an initial backup'
LT_DIRECTORY="/root/backups/etc-before-wp-in-a-box-$(date +%F)"
if [ ! -d "$LT_DIRECTORY" ]; then
	cp -a /etc $LT_DIRECTORY
fi

# install dependencies
echo 'Updating the server'
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y
apt-get autoremove -y

LOCAL_WPINABOX_REPO=/root/git/wp-in-a-box

if [ -d $LOCAL_WPINABOX_REPO ] ; then
    cd $LOCAL_WPINABOX_REPO
    git pull origin master
    git pull --recurse-submodules
    cd -
else
    DEBIAN_FRONTEND=noninteractive apt-get install git -y
    git clone --recursive https://github.com/pothi/wp-in-a-box $LOCAL_WPINABOX_REPO
fi

source $LOCAL_WPINABOX_REPO/scripts/base-installation.sh
source $LOCAL_WPINABOX_REPO/scripts/setup-linux-tweaks.sh
source $LOCAL_WPINABOX_REPO/scripts/install-nginx.sh
source $LOCAL_WPINABOX_REPO/scripts/install-mysql.sh
source $LOCAL_WPINABOX_REPO/scripts/create-sftp-user.sh
source $LOCAL_WPINABOX_REPO/scripts/install-php7.sh

# the following can be executed at any order
# source $LOCAL_WPINABOX_REPO/scripts/install-firewall.sh
source $LOCAL_WPINABOX_REPO/scripts/emergency-user-creation.sh
source $LOCAL_WPINABOX_REPO/scripts/swap.sh

# post-install steps
codename=`lsb_release -i -s`
case "$codename" in
    "stretch")
        source $LOCAL_WPINABOX_REPO/scripts/post-install-stretch.sh
        ;;
    "xenial")
        source $LOCAL_WPINABOX_REPO/scripts/post-install-xenial.sh
        ;;
    "*")
        echo 'Could not figure out the distribution. Skipping post-install steps!'
        ;;
esac

# take a backup, after doing everything
echo 'Taking a final backup'
LT_DIRECTORY="/root/backups/etc-after-wp-in-a-box-$(date +%F)"
if [ ! -d "$LT_DIRECTORY" ]; then
	cp -a /etc $LT_DIRECTORY
fi

# logout and then login to see the changes
echo 'All done.'

echo '-----------------------------------'
echo '-----------------------------------'
echo "SFTP username is $WP_SFTP_USER"
echo "SFTP password is $WP_SFTP_PASS"
echo '-----------------------------------'
echo "Emergency username is $ICE_USER"
echo "Emergency password is $ICE_PASS"
echo '-----------------------------------'
echo '-----------------------------------'
echo 'Please type vi or vim as root to install vim plugins globally'
echo '-----------------------------------'

echo 'Please make a note of these somewhere safe'
echo 'Also please test if things are okay!'

echo 'You may reboot only once to apply all changes globally!'
echo 'Or you may just logout and then log back in to see certain changes'
echo
