#!/bin/bash

if [ free | grep -iw swap | awk {'print $2'} -eq 0 ]; then
    echo 'Setting up Swap...'
	fallocate -l 1G /swapfile
	chmod 600 /swapfile
	echo '/swapfile none swap sw 0 0' >> /etc/fstab
	mkswap /swapfile
	swapon -a
	swapon -s (verification)

	printf "vm.swappiness=10\nvm.vfs_cache_pressure = 50\n" > /etc/sysctl.d/60-swap-custom.conf

	service procps restart
    echo 'Done setting up swap!'
fi

# else skip this script since swap is already present
# TODO: Setup alert if swap is used
# Not necessary when we use something like DO's built-in monitoring that can alert of memory goes beyond a limi.
