#!/bin/bash

# TODO:
# Setup MySecureShell
# Setup ACL

# Variables - you may send these as command line options
BASE_NAME=web

source /root/.envrc

if [ "$WP_SFTP_USER" == "" ]; then
    # create SFTP username automatically
    WP_SFTP_USER="sftp$(pwgen -A 8 1)"
    echo "export WP_SFTP_USER=$WP_SFTP_USER" >> /root/.envrc
fi

#--- please do not edit below this file ---#

SSHD_CONFIG='/etc/ssh/sshd_config'

if [ ! -d "/home/${BASE_NAME}" ]; then
    groupadd --gid=1010 $WP_SFTP_USER &> /dev/null
    useradd --uid=1010 --gid=1010 -m --home-dir /home/${BASE_NAME}/ $WP_SFTP_USER &> /dev/null
    # use the following, if the user prefers ZSH shell
    # useradd --uid=1010 --gid=1010 --shell=/usr/bin/zsh -m --home-dir /home/${BASE_NAME}/ $WP_SFTP_USER &> /dev/null

    groupadd ${BASE_NAME} &> /dev/null

    # "web" is meant for SFTP only user/s
    gpasswd -a $WP_SFTP_USER ${BASE_NAME} &> /dev/null

    mkdir -p /home/${BASE_NAME}/{.aws,.composer,.ssh,.well-known,Backup,bin,git,log,others,php/session,scripts,sites,src,tmp,mbox,.npm,.wp-cli} &> /dev/null
    mkdir -p /home/${BASE_NAME}/Backup/{files,databases}

    chown -R $WP_SFTP_USER:$WP_SFTP_USER /home/${BASE_NAME}
    chown root:root /home/${BASE_NAME}
    chmod 755 /home/${BASE_NAME}

#-- allow the user to login to the server --#
# older way of doing things by appending it to AllowUsers directive
# if ! grep "$WP_SFTP_USER" ${SSHD_CONFIG} &> /dev/null ; then
  # sed -i '/AllowUsers/ s/$/ '$WP_SFTP_USER'/' ${SSHD_CONFIG}
# fi
# latest way of doing things
# ref: https://knowledgelayer.softlayer.com/learning/how-do-i-permit-specific-users-ssh-access
# groupadd –r sshusers

# if AllowGroups line doesn't exist, insert it only once!
# if ! grep -i "AllowGroups" ${SSHD_CONFIG} &> /dev/null ; then
    # echo '
# # allow users within the (system) group "sshusers"
# AllowGroups sshusers
# ' >> ${SSHD_CONFIG}
# fi

# add new users into the 'sshusers' now
# usermod -a -G sshusers ${WP_SFTP_USER}

# if the text 'match group ${BASE_NAME}' isn't found, then
# insert it only once
if ! grep "Match group ${BASE_NAME}" "${SSHD_CONFIG}" &> /dev/null ; then
    # remove the existing subsystem
    sed -i 's/^Subsystem/### &/' ${SSHD_CONFIG}

    # add new subsystem
echo "
# setup internal SFTP
Subsystem sftp internal-sftp
    Match group ${BASE_NAME}
    ChrootDirectory %h
    X11Forwarding no
    AllowTcpForwarding no
    ForceCommand internal-sftp
" >> ${SSHD_CONFIG}

fi # /Match group ${BASE_NAME}

# echo 'Testing the modified SSH config'
# the following didn't work
# sshd –t
# /usr/sbin/sshd -t
# if [ "$?" != 0 ]; then
    # echo 'Something is messed up in the SSH config file'
    # echo 'Please re-run after fixing errors'
    # echo "See the logfile ${LOG_FILE} for details of the error"
    # echo 'Exiting pre-maturely'
    # exit 1
# else
    # echo 'Cool. Things seem fine.'
    echo 'Restarting SSH Daemon...'
    systemctl restart sshd &> /dev/null
    if [ "$?" != 0 ]; then
        echo 'Something went wrong while creating SFTP user! See below...'; echo; echo;
        systemctl status sshd
    else
        echo 'SSH Daemon restarted!'
        echo 'WARNING: Try to create another SSH connection from another terminal, just incase...!'
        echo 'Do NOT ignore this warning'
    fi
# fi

WP_SFTP_PASS=$(pwgen -s 18 1)

    echo "$WP_SFTP_USER:$WP_SFTP_PASS" | chpasswd

    echo; echo "SFTP username is $WP_SFTP_USER"; echo;
    echo; echo "SFTP password is $WP_SFTP_PASS"; echo;
    echo 'Please make a note of these somewhere safe'
    echo 'Also please test if things are okay!'

    # Next Step - Setup PHP-FPM pool
else
    echo "the default directory /home/${BASE_NAME} already exists!"
    # exit 1
fi # end of if ! -d "/home/${BASE_NAME}" - whoops
