#!/usr/bin/env bash

version=2.0

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

export DEBIAN_FRONTEND=noninteractive

# what's done here

# variables

[ -f ~/.envrc ] && source ~/.envrc
admin_email=${ADMIN_EMAIL:-"root@localhost"}

[ "${EUID:-$(id -u)}" -eq 0 ] || { echo 'You must be root or have sudo privilege to run this script. Exiting now.'; exit 1; }

# take a backup before making changes
[ -d ~/backups ] || mkdir ~/backups
[ -f "$HOME/backups/apt.conf.d-$(date +%F)" ] || cp -a /etc/apt/apt.conf.d ~/backups/apt.conf.d-"$(date +%F)"

printf '%-72s' "Setting up unattended upgrades..."

#--- Changes in /etc/apt/apt.conf.d/20auto-upgrades ---#
auto_up_file=/etc/apt/apt.conf.d/20auto-upgrades
echo 'APT::Periodic::Update-Package-Lists "1";' >| $auto_up_file
echo 'APT::Periodic::Unattended-Upgrade "1";' >> $auto_up_file

#--- Changes in /etc/apt/apt.conf.d/50unattended-upgrades ---#
un_up_file=/etc/apt/apt.conf.d/50unattended-upgrades

# Change #1 - Email address
sed -i '/Mail / s:^//U:U:' $un_up_file
sed -i '/Mail / s:".*":"'"$admin_email"'":' $un_up_file

# Change #2 - When to send the email report
# Set this value to one of:
#    "always", "only-on-error" or "on-change"
# Applicable from Ubuntu 22.04 onwards
mail_report_reason=only-on-error
sed -i '/MailReport/ s:^//U:U:' $un_up_file
sed -i '/MailReport/ s:".*":"'$mail_report_reason'":' $un_up_file
# Change #2.1 - compatibility with older versions Ubuntu 20.04 or below
# it is either true or false (default false)
sed -i '/MailOnlyOnError/ s:^//U:U:' $un_up_file
sed -i '/MailOnlyOnError/ s:".*":"true":' $un_up_file

# Change #3 - Remove unused kernel
sed -i '/Remove\-Unused\-Kernel\-Packages/ s:^//U:U:' $un_up_file
sed -i '/Remove\-Unused\-Kernel\-Packages/ s:".*":"true":' $un_up_file

# Change #4 - apt-get autoremove -y
sed -i '/Remove\-Unused\-Dependencies/ s:^//U:U:' $un_up_file
sed -i '/Remove\-Unused\-Dependencies/ s:".*":"true":' $un_up_file

echo done.

