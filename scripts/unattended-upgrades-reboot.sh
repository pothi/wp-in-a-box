#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

export DEBIAN_FRONTEND=noninteractive

# what's done here

# variables

[ -f ~/.envrc ] && source ~/.envrc
admin_email=${ADMIN_EMAIL:-"root@localhost"}

printf '%-72s' "Setting up unattended upgrades and reboot..."
#--- Unattended Upgrades ---#
echo 'APT::Periodic::Update-Package-Lists "1";' >| /etc/apt/apt.conf.d/20auto-upgrades
echo 'APT::Periodic::Unattended-Upgrade "1";' >> /etc/apt/apt.conf.d/20auto-upgrades

# MailOnlyOnError became legacy setting (but still can be used)
# sed -i '/Unattended-Upgrade::MailOnlyOnError/ s:^//::' /etc/apt/apt.conf.d/50unattended-upgrades

sed -i '/Unattended\-Upgrade::Mail/ s:^//::' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i '/Unattended\-Upgrade::Mail/ s:"":"'$admin_email'":' /etc/apt/apt.conf.d/50unattended-upgrades

sed -i '/Unattended\-Upgrade::MailReport/ s:^//::' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i '/Unattended\-Upgrade::MailReport/ s:".*":"only-on-error":' /etc/apt/apt.conf.d/50unattended-upgrades

echo done.

