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

echo "Done installing MySQL / MariaDB server!"
