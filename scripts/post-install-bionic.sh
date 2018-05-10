#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

echo -n 'Installing certbot... '
apt-get install -qq certbot
echo 'done.'

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