#!/bin/bash

export PMA_USER=pma
export PMA_HOME=/var/www/pma
export PMA_ENV=${PMA_HOME}/.envrc
export PMA_TMP=${PMA_HOME}/phpmyadmin/tmp

mkdir -p /var/www &> /dev/null

useradd --home-dir $PMA_HOME -m $PMA_USER
chown ${PMA_USER} $PMA_HOME

if [ ! -f "${PMA_ENV}" ]; then
    dbuser=pma$(pwgen -cns 5 1)
    dbpass=$(pwgen -cnsv 8 1)
    echo "export pma_db_user=$dbuser" > ${PMA_ENV}
    echo "export pma_db_pass=$dbpass" >> ${PMA_ENV}
    chmod 600 ${PMA_ENV}
    chown $PMA_USER ${PMA_ENV}
    source ${PMA_ENV}
fi

mysql -e "CREATE DATABASE phpmyadmin"
mysql -e "GRANT ALL PRIVILEGES ON phpmyadmin.* TO $pma_db_user@localhost IDENTIFIED BY '$pma_db_pass'"

# sudo -H -u $PMA_USER bash pma-user.sh
sudo -H -u $PMA_USER bash $LOCAL_WPINABOX_REPO/scripts/pma-user.sh

mkdir ${PMA_TMP}
chown ${WP_SFTP_USER}:${WP_SFTP_USER} ${PMA_TMP}
