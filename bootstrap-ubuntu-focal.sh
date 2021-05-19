#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# Version: 1.0

# to be run as root, probably as a user-script just after a server is installed
# https://stackoverflow.com/a/52586842/1004587
# also see https://stackoverflow.com/q/3522341/1004587
is_user_root () { [ "${EUID:-$(id -u)}" -eq 0 ]; }
[ is_user_root ] || { echo 'You must be root or user with sudo privilege to run this script. Exiting now.'; exit 1; }

echo "Script started on (date & time): $(date +%c)"

# Defining return code check function
check_result() {
    if [ $1 -ne 0 ]; then
        echo "Error: $2"
        exit $1
    fi
}

[ ! -f "$HOME/.envrc" ] && touch ~/.envrc
. ~/.envrc

git_usermail=${EMAIL:-root@localhost}
git_username=${NAME:-root}

# Ref: https://wiki.debian.org/Multiarch/HOWTO
# https://askubuntu.com/a/1336013/65814
[ ! $(dpkg --get-selections | grep -q i386) ] && dpkg --remove-architecture i386 2>/dev/null

export DEBIAN_FRONTEND=noninteractive
# the following runs when apt cache is older than an hour
# printf '%-72s' "Updating apt repos..."
echo 'Updating apt cache...'
[ -z "$(find /var/cache/apt/pkgcache.bin -mmin -60 2> /dev/null)" ] && apt-get -qq update
# echo done.


echo Installing prerequisites...
echo -----------------------------------------------------------------------------
required_packages="apt-transport-https \
    curl \
    dnsutils \
    language-pack-en \
    pwgen \
    fail2ban \
    software-properties-common \
    sudo \
    tzdata \
    unzip \
    wget"

for package in $required_packages
do
    if dpkg-query -W -f='${Status}' $package 2>/dev/null | grep -q "ok installed"
    then
        echo "'$package' is already installed"
    else
        printf '%-72s' "Installing '${package}' ..."
        apt-get -qq install $package &> /dev/null
        echo done.
    fi
done

echo -------------------------------------------------------------------------
echo ... done installing prerequisites!
echo

#--- setup timezone ---#
current_time_zone=$(date +\%Z)
if [ "$current_time_zone" != "UTC" ] ; then
    printf '%-72s' "Setting up timezone..."
    ln -fs /usr/share/zoneinfo/UTC /etc/localtime
    dpkg-reconfigure -f noninteractive tzdata
    # timedatectl set-timezone UTC
    check_result $? 'Error setting up timezone.'
    systemctl restart cron
    check_result $? 'Error restarting cron daemon.'
    echo done.
fi

# . $local_wp_in_a_box_repo/scripts/linux-tweaks.sh # bootstrap-root.sh
# . $local_wp_in_a_box_repo/scripts/nginx-installation.sh
echo Installing LEMP...
echo -----------------------------------------------------------------------------
php_ver=7.4
lemp_packages="nginx-extras \
    default-mysql-server \
    php${php_ver}-fpm \
    php${php_ver}-mysql \
    php${php_ver}-gd \
    php${php_ver}-cli \
    php${php_ver}-xml \
    php${php_ver}-mbstring \
    php${php_ver}-soap \
    php${php_ver}-curl \
    php${php_ver}-zip \
    php${php_ver}-bcmath \
    php${php_ver}-imagick"

for package in $lemp_packages
do
    if dpkg-query -W -f='${Status}' $package 2>/dev/null | grep -q "ok installed"
    then
        echo "'$package' is already installed"
    else
        printf '%-72s' "Installing '${package}' ..."
        apt-get -qq install $package &> /dev/null
        echo done.
    fi
done
echo -------------------------------------------------------------------------
echo ... done installing LEMP!
echo
# . $local_wp_in_a_box_repo/scripts/mysql-installation.sh
echo 'Creating a MySQL admin user...'

if [ "$ADMIN_USER" == "" ]; then
    # create MYSQL username automatically
    ADMIN_USER="admin_$(pwgen -Av 6 1)"
    ADMIN_PASS=$(pwgen -cnsv 20 1)
    echo "export ADMIN_USER=$ADMIN_USER" >> /root/.envrc
    echo "export ADMIN_PASS=$ADMIN_PASS" >> /root/.envrc
    mysql -e "CREATE USER ${ADMIN_USER} IDENTIFIED BY '${ADMIN_PASS}';"
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO ${ADMIN_USER} WITH GRANT OPTION"
fi
echo "... created a MySQL admin."
echo "Please check ~/.envrc for credentials."
# . $local_wp_in_a_box_repo/scripts/web-developer-creation.sh
echo 'Creating a WP username...'

wp_user=${WP_USERNAME:-""}
if [ "$wp_user" == "" ]; then
    wp_user="wp_$(pwgen -Av 9 1)"
    echo "export WP_USERNAME=$wp_user" >> /root/.envrc
fi

# home_basename=wp
home_basename=$(echo $wp_user | awk -F _ '{print $1}')
# home_basename=web

if [ ! -d "/home/${home_basename}" ]; then
    useradd --shell=/bin/bash -m --home-dir /home/${home_basename} $wp_user

    groupadd ${home_basename}
    gpasswd -a $wp_user ${home_basename} &> /dev/null
fi

wp_pass=${WP_PASSWORD:-""}
if [ "$wp_pass" == "" ]; then
    wp_pass=$(pwgen -cns 12 1)
    echo "export WP_PASSWORD=$wp_pass" >> /root/.envrc

    echo "$wp_user:$wp_pass" | chpasswd
fi

# provide sudo access without passwd to WP Dev
echo "${wp_user} ALL=(ALL) NOPASSWD:ALL"> /etc/sudoers.d/$wp_user
chmod 400 /etc/sudoers.d/$wp_user

cd /etc/ssh/sshd_config.d
if [ ! -f enable-passwd-auth.conf ]; then
    echo "PasswordAuthentication yes" > enable-passwd-auth.conf
    /usr/sbin/sshd -t && systemctl restart sshd
    check_result $? 'Error restarting SSH daemon while enabling passwd auth.'
else
    echo "Disabling root login"
    if [ ! -f deny-root-login.conf ]; then
        echo "PasswordAuthentication yes" > enable-passwd-auth.conf
        /usr/sbin/sshd -t && systemctl restart sshd
        check_result $? 'Error restarting SSH daemon while denying root login.'
    fi
fi
cd - 1> /dev/null

echo ...created a WP user.
echo "Please check ~/.envrc for credentials."
echo "Test the credentials. And if it works. Re-run this script to disable root login, thus to improve security of this server."

# . $local_wp_in_a_box_repo/scripts/php-installation.sh
php_user=$wp_user
fpm_ini_file=/etc/php/${php_ver}/fpm/php.ini
pool_file=/etc/php/${php_ver}/fpm/pool.d/${php_user}.conf
PM_METHOD=ondemand

user_mem_limit=${PHP_MEM_LIMIT:-""}
[ -z "$user_mem_limit" ] && user_mem_limit=256

max_children=${PHP_MAX_CHILDREN:-""}

if [ -z "$max_children" ]; then
    # let's be safe with a minmal value
    sys_memory=$(free -m | grep -oP '\d+' | head -n 1)
    if (($sys_memory <= 600)) ; then
        max_children=4
    elif (($sys_memory <= 1600)) ; then
        max_children=6
    elif (($sys_memory <= 5600)) ; then
        max_children=10
    elif (($sys_memory <= 10600)) ; then
        PM_METHOD=static
        max_children=20
    elif (($sys_memory <= 20600)) ; then
        PM_METHOD=static
        max_children=40
    elif (($sys_memory <= 30600)) ; then
        PM_METHOD=static
        max_children=60
    elif (($sys_memory <= 40600)) ; then
        PM_METHOD=static
        max_children=80
    else
        PM_METHOD=static
        max_children=100
    fi
fi

if [[ $env_type = "local" ]]; then
    PM_METHOD=ondemand
fi

echo "Configuring memory limit to ${user_mem_limit}MB"
sed -i -e '/^memory_limit/ s/=.*/= '$user_mem_limit'M/' $fpm_ini_file

user_max_filesize=${PHP_MAX_FILESIZE:-64}
echo "Configuring 'post_max_size' and 'upload_max_filesize' to ${user_max_filesize}MB..."
sed -i -e '/^post_max_size/ s/=.*/= '$user_max_filesize'M/' $fpm_ini_file
sed -i -e '/^upload_max_filesize/ s/=.*/= '$user_max_filesize'M/' $fpm_ini_file

user_max_input_vars=${PHP_MAX_INPUT_VARS:-5000}
echo "Configuring 'max_input_vars' to $user_max_input_vars (from the default 1000)..."
sed -i '/max_input_vars/ s/;\? \?\(max_input_vars \?= \?\)[[:digit:]]\+/\1'$user_max_input_vars'/' $fpm_ini_file

# Setup timezone
user_timezone=${USER_TIMEZONE:-UTC}
echo "Configuring timezone to $user_timezone ..."
sed -i -e 's/^;date\.timezone =$/date.timezone = "'$user_timezone'"/' $fpm_ini_file

[ ! -f $pool_file ] && cp /etc/php/${php_ver}/fpm/pool.d/www.conf $pool_file
sed -i -e 's/^\[www\]$/['$php_user']/' $pool_file
sed -i -e 's/www-data/'$php_user'/' $pool_file
sed -i -e '/^;listen.\(owner\|group\|mode\)/ s/^;//' $pool_file
sed -i -e '/^listen.mode = / s/[0-9]\{4\}/0660/' $pool_file

php_ver_short=$(echo $php_ver | sed 's/\.//')
socket=/run/php/fpm-${php_ver_short}-${php_user}.sock
sed -i "/^listen =/ s:=.*:= $socket:" $pool_file
[ -f /etc/nginx/conf.d/lb.conf ] && sed -i "s:/var/lock/php-fpm.*;:$socket;:" /etc/nginx/conf.d/lb.conf
if [ ! -f /etc/nginx/conf.d/fpm${php_ver_short}.conf ]; then
    echo "upstream fpm${php_ver_short} { server unix:$socket; }" > /etc/nginx/conf.d/fpm${php_ver_short}.conf
fi

sed -i -e 's/^pm = .*/pm = '$PM_METHOD'/' $pool_file
sed -i '/^pm.max_children/ s/=.*/= '$max_children'/' $pool_file

PHP_MIN=$(expr $max_children / 10)

sed -i '/^;catch_workers_output/ s/^;//' $pool_file
sed -i '/^;pm.process_idle_timeout/ s/^;//' $pool_file
sed -i '/^;pm.max_requests/ s/^;//' $pool_file
sed -i '/^;pm.status_path/ s/^;//' $pool_file
sed -i '/^;ping.path/ s/^;//' $pool_file
sed -i '/^;ping.response/ s/^;//' $pool_file

# home_basename=web
home_basename=$(echo $wp_user | awk -F _ '{print $1}')
[ ! -d /home/${home_basename}/log ] && mkdir /home/${home_basename}/log
PHP_SLOW_LOG_PATH="\/home\/${home_basename}\/log\/slow-php.log"
sed -i '/^;slowlog/ s/^;//' $pool_file
sed -i '/^slowlog/ s/=.*$/ = '$PHP_SLOW_LOG_PATH'/' $pool_file
sed -i '/^;request_slowlog_timeout/ s/^;//' $pool_file
sed -i '/^request_slowlog_timeout/ s/= .*$/= 60/' $pool_file

FPMCONF="/etc/php/${php_ver}/fpm/php-fpm.conf"
sed -i '/^;emergency_restart_threshold/ s/^;//' $FPMCONF
sed -i '/^emergency_restart_threshold/ s/=.*$/= '$PHP_MIN'/' $FPMCONF
sed -i '/^;emergency_restart_interval/ s/^;//' $FPMCONF
sed -i '/^emergency_restart_interval/ s/=.*$/= 1m/' $FPMCONF
sed -i '/^;process_control_timeout/ s/^;//' $FPMCONF
sed -i '/^process_control_timeout/ s/=.*$/= 10s/' $FPMCONF


echo 'Restarting PHP-FPM...'
/usr/sbin/php-fpm${php_ver} -t 1>/dev/null && systemctl restart php${php_ver}-fpm 1>/dev/null

echo 'Restarting Nginx...'
/usr/sbin/nginx -t 1>/dev/null && systemctl restart nginx 1>/dev/null

echo All done.

echo -------------------------------------------------------------------------
echo You may find the login credentials of SFTP/SSH user in /root/.envrc file.
echo -------------------------------------------------------------------------

echo 'You may reboot only once to apply certain updates (ex: kernel updates)!'
echo

echo "Script ended on (date & time): $(date +%c)"
echo
