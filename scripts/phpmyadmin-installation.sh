#!/bin/bash

PMA_USER=pma

mkdir -p /var/www

useradd --home-dir /var/www/html -m $PMA_USER
chown ${PMA_USER} /var/www/html

if [ ! -f "/var/www/html/.envrc" ]; then
    dbuser=pma$(pwgen -cns 5 1)
    dbpass=$(pwgen -cnsv 8 1)
    echo "export pma_db_user=$dbuser" > /var/www/html/.envrc
    echo "export pma_db_pass=$dbpass" >> /var/www/html/.envrc
    chmod 600 /var/www/html/.envrc
    chown $PMA_USER /var/www/html/.envrc
    source /var/www/html/.envrc
fi

mysql -e "CREATE DATABASE phpmyadmin"
mysql -e "GRANT ALL PRIVILEGES ON phpmyadmin.* TO $pma_db_user@localhost IDENTIFIED BY '$pma_db_pass'"

sudo -H -u $PMA_USER bash pma-user.sh
