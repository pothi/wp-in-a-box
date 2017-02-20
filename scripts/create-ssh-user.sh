#!/bin/bash

# Variables - you may set the following in envrc file
# SSH_USER

source /root/.envrc

if [ "$SSH_USER" == "" ]; then
    # create SSH username automatically
    SSH_USER="ssh$(pwgen -A 8 1)"
    echo "export SSH_USER=$SSH_USER" >> /root/.envrc
fi

#--- please do not edit below this file ---#

SSHD_CONFIG='/etc/ssh/sshd_config'

if [ ! -d "/home/${SSH_USER}" ]; then
    # for low-level utility, use useradd
    adduser $SSH_USER &> /dev/null

    # use the following, if the user prefers ZSH shell
    # chsh --shell /bin/zsh $SSH_USER

    echo "${SSH_USER} ALL=(ALL) NOPASSWD:ALL"> /etc/sudoers.d/$SSH_USER
    chmod 400 /etc/sudoers.d/$SSH_USER

    SSH_PASS=$(pwgen -s 18 1)

    echo "$SSH_USER:$SSH_PASS" | chpasswd

    # Next Step - Setup PHP-FPM pool
else
    echo "the default directory /home/${SSH_USER} already exists!"
    echo "The user '${SSH_USER}' already exists"
    # exit 1
fi # end of if ! -d "/home/${SSH_USER}" - whoops

