#!/bin/bash


###   variables   ###
swap_file='/swapfile'
swap_size='1G'
swap_sysctl_file='/etc/sysctl.d/60-swap-local.conf'
sleep_time_between_tasks=2


# create swap if unavailable
is_swap_enabled=$(free | grep -iw swap | awk {'print $2'}) # 0 means no swap
if [ $is_swap_enabled -eq 0 ]; then
    echo 'Creating and setting up Swap...'
    echo '-------------------------------------------------------------------------'

    # check for swap file
    if [ ! -f $swap_file ]; then
        fallocate -l $swap_size $swap_file &> /dev/null
        if [ $? -ne 0 ]; then
            echo Could not create swap file using fallocate.
        fi
    else
        echo Note: Existing swap file found!
    fi

    # only root should be able to read it
    chmod 600 $swap_file

    # enable swap upon boot
    fstab_entry="$swap_file none swap sw 0 0"
    if ! $(grep -q "^${fstab_entry}$" /etc/fstab &> /dev/null) ; then
        echo $fstab_entry >> /etc/fstab &> /dev/null
    else
        echo Note: /etc/fstab already has an entry for swap!
    fi

    mkswap $swap_file
    if [ $? != 0 ]; then
        echo 'Error running mkswap command while creating swap file. Exiting!'
        exit 1
    fi

    # enable swap
    printf '%-72s' "Waiting for swap file to get ready..."
    sleep $sleep_time_between_tasks
    echo done.
    swapon -a
    if [ $? -ne 0 ]; then
        echo Error enabling swap using the command "swapon -a". Exiting!
    fi

    # display summary of swap (only for logging purpose)
    # swapon -s

    # fine-tune swap
    # printf "# Ref: https://www.digitalocean.com/community/tutorials/how-to-add-swap-on-ubuntu-14-04\n\nvm.swappiness=10\nvm.vfs_cache_pressure = 50\n" > $swap_sysctl_file
    echo '# Ref: https://www.digitalocean.com/community/tutorials/how-to-add-swap-on-ubuntu-14-04' > $swap_sysctl_file
    echo >> $swap_sysctl_file
    echo 'nvm.swappiness=10' >> $swap_sysctl_file
    echo 'nvm.vfs_cache_pressure = 50' >> $swap_sysctl_file

    # apply changes
    service procps restart
    # alternative way
    # sysctl -p $swap_sysctl_file
    if [ $? != 0 ]; then
        echo Error restarting procps!
    fi

    echo -------------------------------------------------------------------------
    echo ... done setting up swap!
fi

# TODO: Setup alert if swap is used
# Not necessary when we use something like DO's built-in monitoring that can alert of memory goes beyond a limit.
