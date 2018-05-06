#!/bin/bash

# Version: 1.3

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
    echo -n "Taking an initial backup at $LT_DIRECTORY..."
    mkdir $LT_DIRECTORY
    cp -a /etc $LT_DIRECTORY
    echo ' done.'
fi

export DEBIAN_FRONTEND=noninteractive
apt-get -qq update
echo -n Installing git...
apt-get -qq install git
echo ' done.'
source ~/.envrc &> /dev/null
if [ -z "$EMAIL" ] ; then
    export EMAIL=user@example.com
fi
git config --global --replace-all user.email "$EMAIL"

if [ -z "$NAME" ] ; then
    export NAME='Firstname Lastname'
fi
git config --global --replace-all user.name "$NAME"

echo -n Installing etckeeper...
# sending the output to /dev/null to reduce the noise
apt-get -qq install etckeeper &> /dev/null
sed -i 's/^GIT_COMMIT_OPTIONS=""$/GIT_COMMIT_OPTIONS="--quiet"/' /etc/etckeeper/etckeeper.conf
echo ' done.'

LOCAL_WPINABOX_REPO=/root/git/wp-in-a-box

echo -n 'Fetching wp-in-a-box repo'
if [ -d $LOCAL_WPINABOX_REPO ] ; then
    cd $LOCAL_WPINABOX_REPO
    git pull -q origin master
    git pull -q --recurse-submodules
    cd - &> /dev/null
else
    git clone -q --recursive https://github.com/pothi/wp-in-a-box $LOCAL_WPINABOX_REPO
fi
echo ' done.'

# create swap at first
source $LOCAL_WPINABOX_REPO/scripts/swap.sh

# install dependencies
echo -n 'Updating installed packages...'
apt-get -qq upgrade
apt-get -qq dist-upgrade
apt-get -qq autoremove
echo " done."

source $LOCAL_WPINABOX_REPO/scripts/base-installation.sh
source $LOCAL_WPINABOX_REPO/scripts/mta-installation.sh
source $LOCAL_WPINABOX_REPO/scripts/setup-linux-tweaks.sh
source $LOCAL_WPINABOX_REPO/scripts/nginx-installation.sh
source $LOCAL_WPINABOX_REPO/scripts/mysql-installation.sh
source $LOCAL_WPINABOX_REPO/scripts/create-sftp-user.sh
source $LOCAL_WPINABOX_REPO/scripts/php7-installation.sh
source $LOCAL_WPINABOX_REPO/scripts/phpmyadmin-installation.sh

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

echo 'You may reboot only once to apply certain updates (hint: kernel updates)!'
echo
