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
LT_DIRECTORY="/root/backups/etc-linux-tweaks-$(date +%F)"
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

source /root/wp-in-a-box/scripts/setup-linux-tweaks.sh
source /root/wp-in-a-box/scripts/install-base.sh
source /root/wp-in-a-box/scripts/install-firewall.sh
source /root/wp-in-a-box/scripts/install-nginx.sh
source /root/wp-in-a-box/scripts/install-mysql.sh
source /root/wp-in-a-box/scripts/create-sftp-user.sh
source /root/wp-in-a-box/scripts/create-ssh-user.sh
source /root/wp-in-a-box/scripts/install-php7.sh

# take a backup, after doing everything
echo 'Taking a final backup'
LT_DIRECTORY="/root/backups/etc-linux-tweaks-after-$(date +%F)"
if [ ! -d "$LT_DIRECTORY" ]; then
	cp -a /etc $LT_DIRECTORY
fi

# logout and then login to see the changes
echo 'All done.'

echo; echo "SSH username is $SSH_USER"; echo;
echo; echo "SSH password is $SSH_PASS"; echo;
echo 'Please make a note of these somewhere safe'
echo 'Also please test if things are okay!'

echo 'You may reboot only once to apply all changes globally!'
echo 'Or you may just logout and then log back in to see certain changes'
echo
