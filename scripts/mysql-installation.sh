#!/bin/bash

echo 'Installing MySQL / MariaDB Server'
# lets check if mariadb-server exists
SQL_SERVER=mariadb-server
if ! apt-cache show mariadb-server &> /dev/null ; then SQL_SERVER=mysql-server ; fi

DEBIAN_FRONTEND=noninteractive apt-get install ${SQL_SERVER} -qq &> /dev/null

systemctl stop mysql
# enable slow log and other tweaks
cp $LOCAL_WPINABOX_REPO/config/mariadb.conf.d/*.cnf /etc/mysql/mariadb.conf.d/
systemctl start mysql

source /root/.envrc

echo 'Setting up MySQL user...'

if [ "$MYSQL_ADMIN_USER" == "" ]; then
    # create MYSQL username automatically
    MYSQL_ADMIN_USER="sqladmin_$(pwgen -A 8 1)"
    MYSQL_ADMIN_PASS=$(pwgen -cnsv 20 1)
    echo "export MYSQL_ADMIN_USER=$MYSQL_ADMIN_USER" >> /root/.envrc
    echo "export MYSQL_ADMIN_PASS=$MYSQL_ADMIN_PASS" >> /root/.envrc
    mysql -e "CREATE USER ${MYSQL_ADMIN_USER}@localhost IDENTIFIED BY '${MYSQL_ADMIN_PASS}';"
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO ${MYSQL_ADMIN_USER}@localhost WITH GRANT OPTION"
fi

echo "Done installing MySQL / MariaDB server!"
