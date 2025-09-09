#!/usr/bin/env bash

VERSION=1.0

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# what's done here

# variables
# WP_USERNAME / DEV_USER

###---------- Please do not edit below this line ----------###

export PATH=~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
export DEBIAN_FRONTEND=noninteractive

local_wp_in_a_box_repo=/root/git/wp-in-a-box
[ -f /root/.envrc ] && . /root/.envrc

php_user=${WP_USERNAME:-""}
if [ -z "$php_user" ]; then
    echo 'WP_USERNAME environmental variable is not found.'
    echo 'If you use a different variable name for your developer, please update the script or /root/.envrc file and re-run.'
    echo 'Developer env variable is not found. Exiting prematurely!'; exit
fi

PMA_USER=pma
PMA_HOME=/var/www/pma
PMA_ENV=${PMA_HOME}/.envrc
PMA_TMP=${PMA_HOME}/phpmyadmin/tmp

source ${PMA_ENV}

mysql -e "DROP DATABASE phpmyadmin" > /dev/null
mysql -e "DROP USER $pma_db_user@localhost" > /dev/null

crontab -u ${PMA_USER} -r

rm -rf ${PMA_HOME}
userdel $PMA_USER >/dev/null

