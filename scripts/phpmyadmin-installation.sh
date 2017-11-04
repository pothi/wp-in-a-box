#!/bin/bash

export PMA_USER=pma
export PMA_HOME=/var/www/pma

mkdir -p /var/www &> /dev/null

useradd --home-dir $PMA_HOME -m $PMA_USER
chown ${PMA_USER} $PMA_HOME

if [ ! -f "/var/www/html/.envrc" ]; then
    dbuser=pma$(pwgen -cns 5 1)
    dbpass=$(pwgen -cnsv 8 1)
    echo "export pma_db_user=$dbuser" > ${PMA_HOME}/.envrc
    echo "export pma_db_pass=$dbpass" >> ${PMA_HOME}/.envrc
    chmod 600 ${PMA_HOME}/.envrc
    chown $PMA_USER ${PMA_HOME}/.envrc
    source ${PMA_HOME}/.envrc
fi

mysql -e "CREATE DATABASE phpmyadmin"
mysql -e "GRANT ALL PRIVILEGES ON phpmyadmin.* TO $pma_db_user@localhost IDENTIFIED BY '$pma_db_pass'"

sudo -H -u $PMA_USER bash pma-user.sh
