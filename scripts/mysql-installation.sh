#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

export DEBIAN_FRONTEND=noninteractive

# echo 'Installing MySQL / MariaDB Server'
echo 'Installing MySQL Server'
# lets check if mariadb-server exists
# sql_server=mariadb-server
# if ! apt-cache show mariadb-server &> /dev/null ; then sql_server=mysql-server ; fi

sql_server=default-mysql-server

apt-get install pwgen ${sql_server} -qq &> /dev/null

# systemctl stop mysql
# enable slow log and other tweaks
# local_wp_in_a_box_repo=/root/git/wp-in-a-box
# cp $local_wp_in_a_box_repo/config/mysql.conf.d/*.cnf /etc/mysql/conf.d/
# systemctl start mysql

[ -f /root/.envrc ] && . /root/.envrc

echo 'Setting up MySQL admin user...'

if [ "$ADMIN_USER" == "" ]; then
    # create MYSQL username automatically
    ADMIN_USER="sql_$(pwgen -Av 6 1)"
    ADMIN_PASS=$(pwgen -cnsv 20 1)
    echo "export ADMIN_USER=$ADMIN_USER" >> /root/.envrc
    echo "export ADMIN_PASS=$ADMIN_PASS" >> /root/.envrc
    mysql -e "CREATE USER ${ADMIN_USER} IDENTIFIED BY '${ADMIN_PASS}';"
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO ${ADMIN_USER} WITH GRANT OPTION"
fi
echo ... done setting up MySQL user.

echo ... done installing MySQL / MariaDB server!
