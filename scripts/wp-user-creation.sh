#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# what's done here

# variables

# Variables - you may send these as command line options
# wp_user

. /root/.envrc

echo 'Creating a WP username...'

wp_user=${WP_USERNAME:-""}
if [ "$wp_user" == "" ]; then
    # create SFTP username automatically
    wp_user="wp_$(pwgen -Av 9 1)"
    echo "export WP_USER=$wp_user" >> /root/.envrc
fi

home_basename=$(echo $wp_user | awk -F _ '{print $1}')

#--- please do not edit below this file ---#

SSHD_CONFIG='/etc/ssh/sshd_config'

if [ ! -d "/home/${home_basename}" ]; then
    useradd --shell=/bin/bash -m --home-dir /home/${home_basename} $wp_user

    groupadd ${home_basename}
    gpasswd -a $wp_user ${home_basename} &> /dev/null
fi

wp_pass=${WP_PASSWORD:-""}
if [ "$wp_pass" == "" ]; then
    wp_pass=$(pwgen -cns 12 1)
    echo "export WP_PASSWORD=$wp_pass" >> /root/.envrc

    echo "$wp_user:$wp_pass" | chpasswd
fi

# cd $local_wp_in_a_box_repo/scripts/ &> /dev/null
# sudo -H -u $wp_user bash nvm-nodejs.sh
# cd - &> /dev/null

echo ...done creating a WP user.
