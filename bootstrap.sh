#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# Version: 2.2

# to be run as root, probably as a user-script just after a server is installed

# as root
# if [[ $USER != "root" ]]; then
# echo "This script must be run as root"
# exit 1
# fi

# ref: https://packages.sury.org/php/README.txt
# if [ "$(whoami)" != "root" ]; then
    # SUDO=sudo
# else
    # SUDO=
# fi

is_user_root () { [ "${EUID:-$(id -u)}" -eq 0 ]; }

[ "$is_user_root" ] || { echo 'You must be root or user with sudo privilege to run this script. Exiting now.'; exit 1; }

# create some useful directories - create them on demand
mkdir -p ${HOME}/{backups,git,log,scripts,tmp} &> /dev/null

# logging everything
log_file=${HOME}/log/wp-in-a-box.log
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

[ ! -f "$HOME/.envrc" ] && touch ~/.envrc

# some defaults / variables
BASE_NAME=web
if ! grep -qw $BASE_NAME /root/.envrc ; then
    echo "export BASE_NAME=$BASE_NAME" >> /root/.envrc
fi

EMAIL=root@localhost
if ! grep -qw $EMAIL /root/.envrc ; then
    echo "export EMAIL=$EMAIL" >> /root/.envrc
fi
NAME='root'
if ! grep -qw "$NAME" /root/.envrc ; then
    echo "export NAME='$NAME'" >> /root/.envrc
fi

local_wp_in_a_box_repo=/root/git/wp-in-a-box

source /root/.envrc

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
    # the following runs only once when apt-get is never run (just after the OS is installed!)
    [ ! -f /var/lib/apt/periodic/update-success-stamp ] && apt-get -qq update

    # the following code runs only when apt cache is more than one day old.
    apt_test_file=/root/tmp/dummy_file_for_apt_test.txt
    touch -d"-1day" $apt_test_file
    [ $apt_test_file -nt /var/lib/apt/periodic/update-success-stamp ] && apt-get -qq update
    # rm $apt_test_file
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
    cd /etc/
    git config user.name "root"
    git config user.email "root@localhost"
    cd - &> /dev/null
echo done.

printf '%-72s' "Fetching wp-in-a-box repo..."
if [ ! -d $local_wp_in_a_box_repo ] ; then
    git clone -q --recursive https://github.com/pothi/wp-in-a-box $local_wp_in_a_box_repo &> /dev/null
else
    git -C $local_wp_in_a_box_repo pull -q origin master &> /dev/null
    git -C $local_wp_in_a_box_repo pull -q --recurse-submodules &> /dev/null
fi
echo done.
echo

# pre-install steps
codename=`lsb_release -c -s`
case "$codename" in
    "focal")
        source $local_wp_in_a_box_repo/scripts/pre-install-focal.sh
        ;;
    "bionic")
        # source $local_wp_in_a_box_repo/scripts/pre-install-bionic.sh
        ;;
    "stretch")
        # source $local_wp_in_a_box_repo/scripts/pre-install-stretch.sh
        ;;
    "xenial")
        # source $local_wp_in_a_box_repo/scripts/pre-install-xenial.sh
        ;;
    *)
        echo "Distro: $codename"
        echo 'Warning: Could not figure out the distribution codename. Skipping pre-install steps!'
        ;;
esac

source $local_wp_in_a_box_repo/scripts/swap.sh
echo
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
source $local_wp_in_a_box_repo/scripts/server-admin-creation.sh
echo

# the following can be executed at any order as they are mostly optional
# source $local_wp_in_a_box_repo/scripts/firewall.sh
echo

# optional software, utilities and packages
# source $local_wp_in_a_box_repo/scripts/optional-installation.sh

# post-install steps
codename=`lsb_release -c -s`
case "$codename" in
    "focal")
        source $local_wp_in_a_box_repo/scripts/post-install-focal.sh
        ;;
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
