#!/usr/bin/env bash

VERSION=2.0

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# what's done here

# variables
# DEV_USER

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

export PMA_USER=pma
export PMA_HOME=/var/www/pma
export PMA_ENV=${PMA_HOME}/.envrc
export PMA_TMP=${PMA_HOME}/phpmyadmin/tmp

[ ! -d /var/www/pma ] && mkdir -p /var/www/pma

useradd --home-dir $PMA_HOME $PMA_USER &> /dev/null
chown ${PMA_USER} $PMA_HOME

if ! command -v pwgen >/dev/null; then
    apt-get -qq install pwgen > /dev/null
fi

if [ ! -f "${PMA_ENV}" ]; then
    dbuser=pma$(pwgen -cns 5 1)
    dbpass=$(pwgen -cnsv 8 1)
    echo "export pma_db_user=$dbuser" > ${PMA_ENV}
    echo "export pma_db_pass=$dbpass" >> ${PMA_ENV}
    chmod 600 ${PMA_ENV}
    chown $PMA_USER ${PMA_ENV}
    . ${PMA_ENV}
fi

mysql -e "CREATE DATABASE phpmyadmin" &> /dev/null
mysql -e "CREATE USER $pma_db_user@localhost IDENTIFIED BY '$pma_db_pass'" &> /dev/null
mysql -e "GRANT ALL PRIVILEGES ON phpmyadmin.* TO $pma_db_user@localhost" &> /dev/null

[ -z $local_wp_in_a_box_repo ] && local_wp_in_a_box_repo=/root/git/wp-in-a-box
# sudo -H -u $PMA_USER bash $local_wp_in_a_box_repo/scripts/pma-installation.sh
cp $local_wp_in_a_box_repo/scripts/pma-installation.sh $PMA_HOME/
chown $PMA_USER $PMA_HOME/pma-installation.sh
runuser -u $PMA_USER bash ${PMA_HOME}/pma-installation.sh
rm ${PMA_HOME}/pma-installation.sh

[ ! -d ${PMA_TMP} ] && mkdir ${PMA_TMP}
# PMA_TMP must be owned by the user that runs PHP.
# In our case, PHP is run as $DEV_USER
chown ${php_user}:${php_user} ${PMA_TMP}
