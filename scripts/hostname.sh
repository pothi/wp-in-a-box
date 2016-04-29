#!/bin/bash

# Sets up hostname and FQDN, if they are not already set, such as in Linode
# DigitalOcean sets it up correctly

# To be run as root

# FQDN = MY_HOSTNAME.MY_DOMAIN
#--- Variables
export MY_HOSTNAME=
export MY_DOMAIN=
# check if the above are empty
# check if the above are already set in some file, for example in zshrc or bashrc
# check if hostname is valid (single word)
# check if the domainname is valid (at least two words)

# TODO: Check if FQDN has been set already
# For example, check for the string 'local'
# check for the number of 'dot's (at least three needed)
# check if hostname contains a single world
# check if the hostname is present in /etc/hosts file
# check if the hostname is present in the FQDN
# check if the domainname contains at least two words
# check if the domainname is part of the FQDN
# get the hostname from /etc/hostname

sed -i "1i127.0.11.1 ${MY_HOSTNAME}.${MY_DOMAIN} $MY_HOSTNAME" /etc/hosts
echo $MY_HOSTNAME > /etc/hostname
hostname -F /etc/hostname

