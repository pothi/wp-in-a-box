#!/bin/bash

# post install script for Ubuntu Xenial

export DEBIAN_FRONTEND=noninteractive
add-apt-repository ppa:certbot/certbot -y
apt-get update -q -y
apt-get install certbot -q -y

#-- For Redis ---#
# one-time process
echo never > /sys/kernel/mm/transparent_hugepage/enabled
# to retain the above modification upon reboot
if ! $(grep -q transparent_hugepage /etc/rc.local) ; then
    echo >> /etc/rc.local
    echo '# for redis - see https://github.com/pothi/wp-in-a-box/issues/51#issuecomment-343657080' >> /etc/rc.local
    echo 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' >> /etc/rc.local
    echo >> /etc/rc.local
fi
