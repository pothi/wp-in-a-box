#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# what's done here

# variables

# logging everything
log_file=/root/log/wp-in-a-box.log
exec > >(tee -a ${log_file} )
exec 2> >(tee -a ${log_file} >&2)

local_wp_in_a_box_repo=/root/git/wp-in-a-box
source /root/.envrc

echo "Optional script started on (date & time): $(date +%c)"

export DEBIAN_FRONTEND=noninteractive

echo
echo Updating the server...
echo ----------------------
printf '%-72s' "Running apt-get upgrade..."
apt-get -qq upgrade &> /dev/null
echo done.
printf '%-72s' "Running apt-get dist-upgrade..."
apt-get -qq dist-upgrade &> /dev/null
echo done.
printf '%-72s' "Running apt-get autoremove..."
apt-get -qq autoremove &> /dev/null
echo done.
echo

source $local_wp_in_a_box_repo/scripts/email-mta-installation.sh
echo

echo Installing optional packages...
echo -----------------------------------------------------------------------------
optional_packages="apt-file \
    apache2-utils \
    acl \
    bc \
    debian-goodies \
    direnv \
    duplicity \
    gawk \
    logwatch \
    mailutils \
    members \
    mlocate \
    molly-guard \
    nmap \
    tree \
    uptimed \
    vim-scripts \
    zip"

for package in $optional_packages
do
    if dpkg-query -s $package &> /dev/null
    then
        echo "$package is already installed"
    else
        printf '%-72s' "Installing ${package}..."
        apt-get -qq install $package &> /dev/null
        echo done.
    fi
done
echo -------------------------------------------------------------------------
echo ... done installing prerequisites!
echo

#--- Setup direnv ---#
# if ! grep 'direnv' /root/.bashrc ; then
    # echo 'eval "$(direnv hook bash)"' >> /root/.bashrc
# fi

#--- Download and setup some helper tools ---#
if [ ! -s /root/ps_mem.py ]; then
    printf '%-72s' "Downloading ps_mem.py script..."
    script_url=http://www.pixelbeat.org/scripts/ps_mem.py
    wget -q -O /root/ps_mem.py $script_url
    check_result $? 'ps_mem.py: error downloading the script.'
    chmod +x /root/ps_mem.py
    echo done.
fi

if [ ! -s /root/scripts/mysqltuner.pl ]; then
    printf '%-72s' "Downloading mysqlturner script..."
    script_url=https://raw.github.com/major/MySQltuner-perl/master/mysqltuner.pl
    wget -q -O /root/scripts/mysqltuner.pl $script_url
    check_result $? 'mysqltuner: error downloading the script.'
    chmod +x /root/scripts/mysqltuner.pl
    echo done.
fi

if [ ! -s /root/scripts/tuning-primer.sh ]; then
    printf '%-72s' "Downloading tuning-primer script..."
    script_url=https://launchpad.net/mysql-tuning-primer/trunk/1.6-r1/+download/tuning-primer.sh
    wget -q -O /root/scripts/tuning-primer.sh $script_url
    check_result $? 'tuning-primer: error downloading the script.'
    chmod +x /root/scripts/tuning-primer.sh
    sed -i 's/\bjoin_buffer\b/&_size/' /root/scripts/tuning-primer.sh
    echo done.
fi

# depends on mysql & php installation
source $local_wp_in_a_box_repo/scripts/pma-user-creation.sh
echo
source $local_wp_in_a_box_repo/scripts/redis.sh
echo

echo "Optional script ended on (date & time): $(date +%c)"
