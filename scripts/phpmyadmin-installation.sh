#!/bin/bash

PMA_USER=pma

useradd -m $PMA_USER &> /dev/null

source ~$PMA_USER/.envrc &> /dev/null

if [ -z "$pma_db_user" ]; then
    dbuser=pma$(pwgen -cns 5 1)
    dbpass=$(pwgen -cnsv 8 1)
    echo "export pma_db_user=$dbuser" > ~$PMA_USER/.envrc
    echo "export pma_db_pass=$dbpass" >> ~$PMA_USER/.envrc
    chmod 600 ~$PMA_USER/.envrc
fi

mysql -e "CREATE DATABASE phpmyadmin"
mysql -e "GRANT ALL PRIVILEGES ON phpmyadmin.* TO $pma_db_user@localhost IDENTIFIED BY '$pma_db_pass'"

sudo -u $PMA_USER bash pma-user.sh &> /dev/null

