#!/bin/bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# Version: 2.1

# to be run as root, probably as a user-script just after a server is installed

# as root
# if [[ $USER != "root" ]]; then
# echo "This script must be run as root"
# exit 1
# fi

# create some useful directories - create them on demand
mkdir -p /root/{backups,git,log,scripts} &> /dev/null

# logging everything
log_file=/root/log/wp-in-a-box.log
exec > >(tee -a ${log_file} )
exec 2> >(tee -a ${log_file} >&2)

echo "Script started on (date & time): $(date +%c)"

# Defining return code check function
check_result() {
    if [ $1 -ne 0 ]; then
        echo "Error: $2"
        exit $1
    fi
}

[ ! -f /root/.envrc ] && touch /root/.envrc

# some defaults / variables
BASE_NAME=web
if ! grep -qw $BASE_NAME /root/.envrc ; then
    echo "export BASE_NAME=$BASE_NAME" >> /root/.envrc
fi

EMAIL=user@example.com
if ! grep -qw $EMAIL /root/.envrc ; then
    echo "export EMAIL=$EMAIL" >> /root/.envrc
fi
NAME='Firstname Lastname'
if ! grep -qw "$NAME" /root/.envrc ; then
    echo "export NAME='$NAME'" >> /root/.envrc
fi

local_wp_in_a_box_repo=/root/git/wp-in-a-box
if ! grep -qw $local_wp_in_a_box_repo /root/.envrc ; then
    echo "export local_wp_in_a_box_repo=$local_wp_in_a_box_repo" >> /root/.envrc
fi

source ~/.envrc

echo First things first...
echo ---------------------

# take a backup
backup_dir="/root/backups/etc-before-wp-in-a-box-$(date +%F)"
if [ ! -d "$backup_dir" ]; then
    printf '%-72s' "Taking initial backup..."
    mkdir $backup_dir
    cp -a /etc $backup_dir
    echo done.
fi

printf '%-72s' "Updating apt repos..."
export DEBIAN_FRONTEND=noninteractive
apt-get -qq update
echo done.

# git is prerequisite for etckeeper
printf '%-72s' "Installing git..."
apt-get -qq install git &> /dev/null
echo done.
git config --global --replace-all user.email "$EMAIL"
git config --global --replace-all user.name "$NAME"

printf '%-72s' "Installing etckeeper..."
# sending the output to /dev/null to reduce the noise
apt-get -qq install etckeeper &> /dev/null
sed -i 's/^GIT_COMMIT_OPTIONS=""$/GIT_COMMIT_OPTIONS="--quiet"/' /etc/etckeeper/etckeeper.conf
echo done.

printf '%-72s' "Fetching wp-in-a-box repo..."
if [ -d $local_wp_in_a_box_repo ] ; then
    cd $local_wp_in_a_box_repo
    git pull -q origin master &> /dev/null
    git pull -q --recurse-submodules &> /dev/null
    cd - &> /dev/null
else
    git clone -q --recursive https://github.com/pothi/wp-in-a-box $local_wp_in_a_box_repo &> /dev/null
fi
echo done.
echo

# create swap at first
source $local_wp_in_a_box_repo/scripts/base-installation.sh
echo
source $local_wp_in_a_box_repo/scripts/linux-tweaks.sh
echo
source $local_wp_in_a_box_repo/scripts/nginx-installation.sh
echo
source $local_wp_in_a_box_repo/scripts/mysql-installation.sh
echo
source $local_wp_in_a_box_repo/scripts/web-developer-creation.sh
echo
source $local_wp_in_a_box_repo/scripts/php-installation.sh
echo

# the following can be executed at any order as they are mostly optional
# source $local_wp_in_a_box_repo/scripts/install-firewall.sh
source $local_wp_in_a_box_repo/scripts/server-admin-creation.sh
echo

# source $local_wp_in_a_box_repo/scripts/optional.sh

# post-install steps
codename=`lsb_release -c -s`
case "$codename" in
    "bionic")
        source $local_wp_in_a_box_repo/scripts/post-install-bionic.sh
        ;;
    "stretch")
        source $local_wp_in_a_box_repo/scripts/post-install-stretch.sh
        ;;
    "xenial")
        source $local_wp_in_a_box_repo/scripts/post-install-xenial.sh
        ;;
    *)
        echo "Distro: $codename"
        echo 'Warning: Could not figure out the distribution codename. Skipping post-install steps!'
        ;;
esac

# logout and then login to see the changes
echo All done.

echo -------------------------------------------------------------------------
echo You may find the login credentials of SFTP/SSH user in /root/.envrc file.
echo -------------------------------------------------------------------------

echo 'You may reboot only once to apply certain updates (ex: kernel updates)!'
echo

echo "Script ended on (date & time): $(date +%c)"
echo
