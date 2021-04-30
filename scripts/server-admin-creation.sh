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
    ssh_user="admin_$(pwgen -A 6 1)"
    echo "export ADMIN_USER=$ssh_user" >> /root/.envrc
fi

home_basename=$(echo $ssh_user | awk -F _ '{print $1}')

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

    useradd --shell=/bin/bash -m --home-dir /home/${home_basename} $ssh_dev

    # groupadd ${home_basename}

    echo "${ssh_user} ALL=(ALL) NOPASSWD:ALL"> /etc/sudoers.d/$ssh_user
    chmod 400 /etc/sudoers.d/$ssh_user

    admin_pass=$(pwgen -cns 12 1)

    echo "$ssh_user:$admin_pass" | chpasswd
    echo "export ADMIN_PASS=$admin_pass" >> /root/.envrc

    gpasswd -a $ssh_user ssh_users &> /dev/null
else
    echo "Note: The default directory /home/${ssh_user} already exists!"
    echo "Note: The user '${ssh_user}' already exists"
fi

if [ ! -f /home/${ssh_user}/.ssh/authorized_keys ]; then
    cp /root/.ssh/authorized_keys /home/${ssh_user}/.ssh/authorized_keys
    chown $ssh_user:$ssh_user /root/.ssh/authorized_keys /home/${ssh_user}/.ssh/authorized_keys
fi

echo ...done setting up SSH user!
