#!/bin/bash

# Variables - you may set the following in envrc file
# system_admin_username

source /root/.envrc

echo "Creating a 'server admin' user..."

if [ "$system_admin_username" == "" ]; then
    # create SSH username automatically
    system_admin_username="ssh_$(pwgen -A 8 1)"
    echo "export system_admin_username=$system_admin_username" >> /root/.envrc
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

if [ ! -d "/home/${system_admin_username}" ]; then
    useradd -m $system_admin_username

    echo "${system_admin_username} ALL=(ALL) NOPASSWD:ALL"> /etc/sudoers.d/$system_admin_username
    chmod 400 /etc/sudoers.d/$system_admin_username

    system_admin_password=$(pwgen -cns 12 1)

    echo "$system_admin_username:$system_admin_password" | chpasswd
    echo "export system_admin_password=$system_admin_password" >> /root/.envrc

    gpasswd -a $system_admin_username ssh_users &> /dev/null
else
    echo "Note: The default directory /home/${system_admin_username} already exists!"
    echo "Note: The user '${system_admin_username}' already exists"
fi

echo ...done setting up SSH user!
