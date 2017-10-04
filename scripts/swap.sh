#!/bin/bash

swapfile=/swapfile

# only create swap if unavailable
swap_enabled=$(free | grep -iw swap | awk {'print $2'}) # output should not be 0
if [ "$swap_enabled" -eq 0 ]; then
    echo 'Swap not found. Creating and setting up Swap...'

    # check if swapfile is found (but not used)
    if [ -f $swapfile ]; then
        fallocate -l 1G $swapfile
        if [ $? != 0 ]; then
            echo 'Could not create swap file using fllocate. Exiting!'
            exit 1
        fi
    else
        echo 'Note: Existing swap file found!'
    fi

    # only root should be able to read it
    chmod 600 /swapfile

    # enable swap upon boot
    fstabentry="$swapfile none swap sw 0 0"
    if ! $(grep -q "^${fstabentry}$" /etc/fstab) ; then
        echo "$swapfile none swap sw 0 0" >> /etc/fstab
    else
        echo "Note: /etc/fstab already has an entry for swap!"
    fi

    mkswap $swapfile
    if [ $? != 0 ]; then
        echo 'Error running mkswap command while creating swap file. Exiting!'
        exit 1
    fi

    # enable swap
    echo "Waiting for swap file to get ready..."
    sleep 5
    swapon -a
    if [ $? != 0 ]; then
        echo 'Error enabling swap using the command "swapon -a". Exiting!'
        exit 1
    fi

    # display summary of swap (only for logging purpose)
    swapon -s

    # fine-tune swap
    printf "# Ref: https://www.digitalocean.com/community/tutorials/how-to-add-swap-on-ubuntu-14-04\n\nvm.swappiness=10\nvm.vfs_cache_pressure = 50\n" > /etc/sysctl.d/60-swap-custom.conf

    # apply changes
    service procps restart
    if [ $? != 0 ]; then
        echo 'Error restarting procps while fine-tuning swap!'
        exit 1
    fi

    echo 'Done setting up swap!'
fi

# TODO: Setup alert if swap is used
# Not necessary when we use something like DO's built-in monitoring that can alert of memory goes beyond a limit.
