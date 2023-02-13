#!/usr/bin/env bash

version=1.0

# Careful when rebooting a server, unattended!

# programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

# what's done here

# variables
REBOOT_TIME="03:45"

is_user_root () { [ "${EUID:-$(id -u)}" -eq 0 ]; }
[ is_user_root ] || { echo 'You must be root or have sudo privilege to run this script. Exiting now.'; exit 1; }

# take a backup before making changes
[ -d ~/backups ] || mkdir ~/backups
[ -f "~/backups/apt.conf.d-$(date +%F)" ] || cp -a $/etc/apt/apt.conf.d ~/backups/apt.conf.d-$(date +%F)

# we used ":" in sed in unattended-upgrades.sh file.
# here, since reboot time has ":" in it, we can't use ":" in sed as separator.
printf '%-72s' "Setting up unattended reboots..."

un_up_file=/etc/apt/apt.conf.d/50unattended-upgrades
sed -i '/Automatic\-Reboot/ s_^//U_U_' $un_up_file
sed -i '/Automatic\-Reboot/ s_""_"true"_' $un_up_file

sed -i '/Automatic\-Reboot\-WithUsers/ s_^//U_U_' $un_up_file
sed -i '/Automatic\-Reboot\-WithUsers/ s_".*"_"false"_' $un_up_file

sed -i '/Automatic\-Reboot\-Time/ s_^//U_U_' $un_up_file
sed -i '/Automatic\-Reboot\-Time/ s_".*"_"'$REBOOT_TIME'"_' $un_up_file

echo done.


