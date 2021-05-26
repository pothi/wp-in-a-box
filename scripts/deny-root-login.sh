#!/usr/bin/bash sh

#TODO: Check if the version of OpenSSH is 8.2 or greater
cd /etc/ssh/sshd_config.d
if [ ! -f deny-root-login.conf ]; then
    echo "PermitRootLogin no" > deny-root-login.conf
fi
cd - 1> /dev/null

/usr/sbin/sshd -t && systemctl restart sshd
