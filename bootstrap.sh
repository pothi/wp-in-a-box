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

# https://stackoverflow.com/a/52586842/1004587
# also see https://stackoverflow.com/q/3522341/1004587
is_user_root () { [ "${EUID:-$(id -u)}" -eq 0 ]; }
[ is_user_root ] || { echo 'You must be root or user with sudo privilege to run this script. Exiting now.'; exit 1; }

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

[ ! -f "$HOME/.envrc" ] && touch ~/.envrc

EMAIL=root@localhost
if ! grep -qw $EMAIL /root/.envrc ; then
    echo "export EMAIL=$EMAIL" >> /root/.envrc
fi
NAME='root'
if ! grep -qw "$NAME" /root/.envrc ; then
    echo "export NAME='$NAME'" >> /root/.envrc
fi

local_wp_in_a_box_repo=/root/git/wp-in-a-box

. /root/.envrc

# take a backup
backup_dir="/root/backups/etc-before-wp-in-a-box-$(date +%F)"
if [ ! -d "$backup_dir" ]; then
    printf '%-72s' "Taking initial backup..."
    mkdir $backup_dir
    cp -a /etc $backup_dir
    echo done.
fi

# Ref: https://wiki.debian.org/Multiarch/HOWTO
# https://askubuntu.com/a/1336013/65814
[ ! $(dpkg --get-selections | grep -q i386) ] && dpkg --remove-architecture i386 2>/dev/null

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

# Redirection explanation: https://unix.stackexchange.com/a/563563/20241
printf '%-72s' "Installing git..."
    if ! dpkg-query -W -f='${Status}' git 2>/dev/null | grep -q "ok installed"; then apt-get -qq install git 1>/dev/null ; fi
echo done.
git config --global --replace-all user.email "$EMAIL"
git config --global --replace-all user.name "$NAME"

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
case "$codename" in
    "focal")
        . $local_wp_in_a_box_repo/scripts/pre-install-focal.sh
        ;;
    "bionic")
        # . $local_wp_in_a_box_repo/scripts/pre-install-bionic.sh
        ;;
    "stretch")
        # . $local_wp_in_a_box_repo/scripts/pre-install-stretch.sh
        ;;
    "xenial")
        # . $local_wp_in_a_box_repo/scripts/pre-install-xenial.sh
        ;;
    "buster")
        ;;
    *)
        echo "Distro: $codename"
        echo 'Warning: Could not figure out the distribution codename. Skipping pre-install steps!'
        ;;
esac

. $local_wp_in_a_box_repo/scripts/swap.sh
echo
. $local_wp_in_a_box_repo/scripts/base-installation.sh
echo
. $local_wp_in_a_box_repo/scripts/linux-tweaks.sh
echo
. $local_wp_in_a_box_repo/scripts/nginx-installation.sh
echo
. $local_wp_in_a_box_repo/scripts/mysql-installation.sh
echo
. $local_wp_in_a_box_repo/scripts/web-developer-creation.sh
echo
. $local_wp_in_a_box_repo/scripts/php-installation.sh
echo
. $local_wp_in_a_box_repo/scripts/server-admin-creation.sh
echo

# the following can be executed at any order as they are mostly optional
# . $local_wp_in_a_box_repo/scripts/firewall.sh
echo

# optional software, utilities and packages
# . $local_wp_in_a_box_repo/scripts/optional-installation.sh

# post-install steps
case "$codename" in
    "focal")
        . $local_wp_in_a_box_repo/scripts/post-install-focal.sh
        ;;
    "bionic")
        . $local_wp_in_a_box_repo/scripts/post-install-bionic.sh
        ;;
    "stretch")
        . $local_wp_in_a_box_repo/scripts/post-install-stretch.sh
        ;;
    "xenial")
        . $local_wp_in_a_box_repo/scripts/post-install-xenial.sh
        ;;
    "buster")
        # . $local_wp_in_a_box_repo/scripts/post-install-buster.sh
        ;;
    *)
        echo "Distro: $codename"
        echo 'Warning: Could not figure out the distribution codename. Skipping post-install steps!'
        ;;
esac

printf '%-72s' "Installing etckeeper..."
    if ! dpkg-query -W -f='${Status}' etckeeper 2> /dev/null | grep -q "ok installed"; then apt-get -qq install etckeeper &> /dev/null; fi
    sed -i 's/^GIT_COMMIT_OPTIONS=""$/GIT_COMMIT_OPTIONS="--quiet"/' /etc/etckeeper/etckeeper.conf
    cd /etc/
    git config user.name "root"
    git config user.email "root@localhost"
    cd - &> /dev/null
echo done.

# logout and then login to see the changes
echo All done.

echo -------------------------------------------------------------------------
echo You may find the login credentials of SFTP/SSH user in /root/.envrc file.
echo -------------------------------------------------------------------------

echo 'You may reboot only once to apply certain updates (ex: kernel updates)!'
echo

echo "Script ended on (date & time): $(date +%c)"
echo
