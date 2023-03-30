#!/usr/bin/env bash

version=2.0

# based on https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-22-04

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# references:
# https://stackoverflow.com/q/257844/1004587
# https://askubuntu.com/q/1017309/65814

# what's done here


is_user_root() { [ "${EUID:-$(id -u)}" -eq 0 ]; }
[ is_user_root ] || { echo 'You must be root or have sudo privilege to run this script. Exiting now.'; exit 1; }

[ -f "$HOME/.envrc" ] && source ~/.envrc

# variables
swap_file='/swapfile'
swap_size=${SWAP_SIZE:-'1G'}
swap_sysctl_file='/etc/sysctl.d/60-swap-local.conf'
sleep_time_between_tasks=2

# take a backup before making changes
[ -d ~/backups ] || mkdir ~/backups
[ -f "$HOME/backups/fstab-$(date +%F)" ] || cp /etc/fstab ~/backups/fstab-"$(date +%F)"

# helper function to exit upon non-zero exit code of a command
# usage some_command; check_result $? 'some_command failed'
if ! $(type 'check_result' 2>/dev/null | grep -q 'function') ; then
    check_result() {
        if [ "$1" -ne 0 ]; then
            echo -e "\nError: $2. Exiting!\n"
            exit "$1"
        fi
    }
fi

create_swap() {
    return
}

remove_swap() {
    swapoff "$swap_file"

    # Remove swap file
    [ -f "$swap_file" ] && rm "$swap_file"

    # Remove fstab entry
    if grep -q swap /etc/fstab >/dev/null ; then
        sed -i '/swap/d' /etc/fstab
    fi

    [ -f "$swap_sysctl_file" ] && rm "$swap_sysctl_file"
    service procps force-reload
    check_result $? "Error reloading procps!"
}

# Parse Flags
parse_args() {
  while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
    -s | --size)
        swap_size=$2
        shift
        shift
        ;;
    --force-install | --force-no-brew)
        shift
        ;;
    -r | --remove)
        remove_swap
        exit
        ;;
    -v | --version)
        echo "Version: $version"
        exit
        ;;
    *)
        echo "Unrecognized argument $key"
        exit 1
        ;;
    esac
  done
}

parse_args "$@"

# create swap if unavailable
is_swap_enabled=$(free | grep -iw swap | awk {'print $2'}) # 0 means no swap
if [ "$is_swap_enabled" -eq 0 ]; then
    printf '%-72s' 'Creating and setting up Swap...'
    # echo -----------------------------------------------------------------------------

    # check for swap file
    if [ ! -f $swap_file ]; then
        # on a desktop, we may use fdisk to create a partition to be used as swap
        fallocate -l "$swap_size" "$swap_file" >/dev/null
        check_result $? "Error: fallocate failed!"
    fi

    # only root should be able to read it or / and write into it
    chmod 600 $swap_file

    # mark a file / partition as swap
    mkswap $swap_file >/dev/null
    check_result $? 'mkswap failed.'

    # enable swap
    # printf '%-72s' "Waiting for swap file to get ready..."
    # sleep $sleep_time_between_tasks
    # echo done.

    swapon "$swap_file"
    check_result $? "Error executing 'swapon $swap_file'. Exiting!"

    # display summary of swap (only for logging purpose)
    # swapon --show
    # swapon -s

    # to make the above changes permanent
    # enable swap upon boot
    if ! grep -qw swap /etc/fstab ; then
        echo "$swap_file none swap sw 0 0" >> /etc/fstab
    fi

    # fine-tune swap
    if [ ! -f $swap_sysctl_file ]; then
        echo -e "# Ref: https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-22-04\n" > $swap_sysctl_file
        echo 'vm.swappiness=10' >> $swap_sysctl_file
        echo 'vm.vfs_cache_pressure = 50' >> $swap_sysctl_file
    fi

    # apply changes
    # as per /etc/sysctl.d/README.sysctl
    if ! service procps force-reload ; then
        echo Error reloading procps!
    fi
    # alternative way
    # sysctl -p $swap_sysctl_file

    # echo -----------------------------------------------------------------------------
    echo done!
fi

# TODO: Setup alert if swap is used
# Not necessary when we use something like DO's built-in monitoring that can alert of memory goes beyond a limit.

