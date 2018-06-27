#!/bin/bash

export PMA_USER=pma
export PMA_HOME=/var/www/pma
export PMA_ENV=${PMA_HOME}/.envrc
export PMA_TMP=${PMA_HOME}/phpmyadmin/tmp

[ ! -d /var/www ] && mkdir -p /var/www

useradd --home-dir $PMA_HOME -m $PMA_USER &> /dev/null
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

mysql -e "CREATE DATABASE phpmyadmin" &> /dev/null
mysql -e "GRANT ALL PRIVILEGES ON phpmyadmin.* TO $pma_db_user@localhost IDENTIFIED BY '$pma_db_pass'" &> /dev/null

cd $local_wp_in_a_box_repo/scripts/ &> /dev/null
sudo -H -u $PMA_USER bash pma-user-creation.sh
cd - &> /dev/null

[ ! -d ${PMA_TMP} ] && mkdir ${PMA_TMP}
chown ${SFTP_USER}:${SFTP_USER} ${PMA_TMP}
