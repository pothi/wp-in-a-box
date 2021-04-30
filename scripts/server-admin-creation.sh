#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# what's done here

# Variables - you may set the following in envrc file
# ssh_user

source /root/.envrc
ssh_user=${ADMIN_USER:-""}

echo "Creating a 'server admin' user..."

if [ "$ssh_user" == "" ]; then
    # create SSH username automatically
    ssh_user="admin_$(pwgen -Av 6 1)"
    echo "export ADMIN_USER=$ssh_user" >> /root/.envrc
fi

admin_basename=$(echo $ssh_user | awk -F _ '{print $1}')

SSHD_CONFIG='/etc/ssh/sshd_config'

if ! grep -qw ssh_users $SSHD_CONFIG ; then
    groupadd ssh_users &> /dev/null

    echo '
                Match group ssh_users
                PasswordAuthentication yes
    ' >> $SSHD_CONFIG

    echo 'Restarting SSH daemon...'
    systemctl restart sshd &> /dev/null
    if [ $? -ne 0 ]; then
        echo 'Something went wrong while creating SSH user! See below...'; echo; echo;
        systemctl status sshd
    else
        echo ... SSH Daemon restarted!
    fi
fi

if [ ! -d "/home/${ssh_user}" ]; then
    # useradd -m $ssh_user

    useradd --shell=/bin/bash -m $ssh_user

    # groupadd ${admin_basename}

    echo "${ssh_user} ALL=(ALL) NOPASSWD:ALL"> /etc/sudoers.d/$ssh_user
    chmod 400 /etc/sudoers.d/$ssh_user

    gpasswd -a $ssh_user ssh_users &> /dev/null
else
    echo "Note: The default directory /home/${admin_basename} already exists!"
    echo "Note: The user '${ssh_user}' already exists"
fi

ssh_pass=${ADMIN_PASS:-""}
if [ "$ssh_pass" == "" ]; then
    ssh_pass=$(pwgen -cns 12 1)

    echo "$ssh_user:$ssh_pass" | chpasswd
    echo "export ADMIN_PASS=$ssh_pass" >> /root/.envrc
fi


if [ ! -f /home/${admin_basename}/.ssh/authorized_keys ]; then
    [ ! -d /home/${admin_basename}/.ssh ] && { mkdir /home/${admin_basename}/.ssh && chmod 700 /home/${admin_basename}/.ssh }
    [ -f /root/.ssh/authorized_keys ] && cp /root/.ssh/authorized_keys /home/${admin_basename}/.ssh/authorized_keys
    chown -R $ssh_user:$ssh_user /home/${admin_basename}/.ssh
fi

echo ...done setting up SSH user!
