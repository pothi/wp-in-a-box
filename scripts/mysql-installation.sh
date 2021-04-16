#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

export DEBIAN_FRONTEND=noninteractive

# echo 'Installing MySQL / MariaDB Server'
echo 'Installing MySQL Server'
# lets check if mariadb-server exists
# sql_server=mariadb-server
# if ! apt-cache show mariadb-server &> /dev/null ; then sql_server=mysql-server ; fi

sql_server=mysql-server

apt-get install ${sql_server} -qq &> /dev/null

systemctl stop mysql
# enable slow log and other tweaks
cp $local_wp_in_a_box_repo/config/mysql.conf.d/*.cnf /etc/mysql/mysql.conf.d/
systemctl start mysql

source /root/.envrc

echo 'Setting up MySQL admin user...'

if [ "$MYSQL_ADMIN_USER" == "" ]; then
    # create MYSQL username automatically
    MYSQL_ADMIN_USER="sqladmin_$(pwgen -A 8 1)"
    MYSQL_ADMIN_PASS=$(pwgen -cnsv 20 1)
    echo "export MYSQL_ADMIN_USER=$MYSQL_ADMIN_USER" >> /root/.envrc
    echo "export MYSQL_ADMIN_PASS=$MYSQL_ADMIN_PASS" >> /root/.envrc
    # mysql -e "CREATE USER ${MYSQL_ADMIN_USER}@localhost IDENTIFIED BY '${MYSQL_ADMIN_PASS}';"
    # mysql -e "GRANT ALL PRIVILEGES ON *.* TO ${MYSQL_ADMIN_USER}@localhost WITH GRANT OPTION"
    mysql -e "CREATE USER ${MYSQL_ADMIN_USER} IDENTIFIED BY '${MYSQL_ADMIN_PASS}';"
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO ${MYSQL_ADMIN_USER} WITH GRANT OPTION"
fi
echo ... done setting up MySQL user.

echo ... done installing MySQL / MariaDB server!
