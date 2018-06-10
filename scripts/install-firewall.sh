#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

echo 'Setting up ufw...'

apt-get install -q -y ufw

# UFW
ufw default deny incoming

ufw allow 22
ufw allow 80
ufw allow 443
ufw limit ssh comment 'Rate limit for SSH server'

ufw --force enable
if [ $? != 0 ]; then
    echo 'Error setting up firewall'
fi

echo "... done setting up UFW!"
