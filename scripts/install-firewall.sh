#!/bin/bash

DEBIAN_FRONTEND=noninteractive apt-get install -y fail2ban ufw

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

