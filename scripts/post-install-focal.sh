#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# what's done here

# variables


export DEBIAN_FRONTEND=noninteractive

echo 'Ubuntu Focal Fossa (2020.04) specific changes:'
echo ----------------------------------------------
echo Installing certbot...

sudo snap install core
sudo snap refresh core
sudo apt-get -qq remove certbot
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

echo done.

#-- For Redis ---#
# one-time process
# echo never > /sys/kernel/mm/transparent_hugepage/enabled
# to retain the above modification upon reboot
# if ! grep -q transparent_hugepage /etc/rc.local &> /dev/null ; then
    # echo >> /etc/rc.local
    # echo '# for redis - see https://github.com/pothi/wp-in-a-box/issues/51#issuecomment-343657080' >> /etc/rc.local
    # echo 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' >> /etc/rc.local
    # echo >> /etc/rc.local
# fi
