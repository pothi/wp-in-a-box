#!/bin/bash

# Variables - you may set the following in envrc file
# SSH_USER

echo "Setting up emergency user..."

source /root/.envrc

if [ "$SSH_USER" == "" ]; then
    # create SSH username automatically
    SSH_USER="ice_$(pwgen -A 8 1)"
    echo "export SSH_USER=$SSH_USER" >> /root/.envrc
fi

#--- please do not edit below this file ---#

SSHD_CONFIG='/etc/ssh/sshd_config'

if [ ! -d "/home/${SSH_USER}" ]; then
    useradd -m $SSH_USER

    echo "${SSH_USER} ALL=(ALL) NOPASSWD:ALL"> /etc/sudoers.d/$SSH_USER
    chmod 400 /etc/sudoers.d/$SSH_USER

    SSH_PASS=$(pwgen -cns 12 1)

    echo "$SSH_USER:$SSH_PASS" | chpasswd
else
    echo "Note: The default directory /home/${SSH_USER} already exists!"
    echo "Note: The user '${SSH_USER}' already exists"
fi

echo "Done setting up the emergency user!"
