#!/bin/bash

PMA_USER=pma

useradd --home-dir /var/www/html -m $PMA_USER &> /dev/null

source /home/$PMA_USER/.envrc &> /dev/null

if [ -z "$pma_db_user" ]; then
    dbuser=pma$(pwgen -cns 5 1)
    dbpass=$(pwgen -cnsv 8 1)
    echo "export pma_db_user=$dbuser" > /home/$PMA_USER/.envrc
    echo "export pma_db_pass=$dbpass" >> /home/$PMA_USER/.envrc
    chmod 600 /home/$PMA_USER/.envrc
    chown $PMA_USER /home/$PMA_USER/.envrc
    source /home/$PMA_USER/.envrc
fi

mysql -e "CREATE DATABASE phpmyadmin"
mysql -e "GRANT ALL PRIVILEGES ON phpmyadmin.* TO $pma_db_user@localhost IDENTIFIED BY '$pma_db_pass'"

sudo -H -u $PMA_USER bash pma-user.sh &> /dev/null

