#!/bin/bash

# Variables - you may set the following in envrc file
# SSH_USER

echo "Setting up SSH user..."

source /root/.envrc

if [ "$SSH_USER" == "" ]; then
    # create SSH username automatically
    SSH_USER="ssh_$(pwgen -A 8 1)"
    echo "export SSH_USER=$SSH_USER" >> /root/.envrc
fi

#--- please do not edit below this file ---#

SSHD_CONFIG='/etc/ssh/sshd_config'

groupadd ssh_users &> /dev/null

echo '
            Match group ssh_users
            PasswordAuthentication yes
' >> $SSHD_CONFIG

echo 'Restarting SSH daemon...'
systemctl restart sshd &> /dev/null
if [ $? -ne 0 ]; then
    echo 'Something went wrong while creating SFTP user! See below...'; echo; echo;
    systemctl status sshd
else
    echo ... SSH Daemon restarted!
fi

if [ ! -d "/home/${SSH_USER}" ]; then
    useradd -m $SSH_USER

    echo "${SSH_USER} ALL=(ALL) NOPASSWD:ALL"> /etc/sudoers.d/$SSH_USER
    chmod 400 /etc/sudoers.d/$SSH_USER

    SSH_PASS=$(pwgen -cns 12 1)

    echo "$SSH_USER:$SSH_PASS" | chpasswd
    echo "export SSH_PASS=$SSH_PASS" >> /root/.envrc

    gpasswd -a $SSH_USER ssh_users &> /dev/null
else
    echo "Note: The default directory /home/${SSH_USER} already exists!"
    echo "Note: The user '${SSH_USER}' already exists"
fi

echo ...done setting up SSH user!
