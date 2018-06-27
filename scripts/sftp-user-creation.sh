#!/bin/bash

# Variables - you may send these as command line options
BASE_NAME=web
if ! grep -qw $BASE_NAME /root/.envrc ; then
    echo "export BASE_NAME=$BASE_NAME" >> /root/.envrc
fi

source /root/.envrc

echo 'Setting up SFTP user...'

if [ "$SFTP_USER" == "" ]; then
    # create SFTP username automatically
    SFTP_USER="sftp_$(pwgen -A 8 1)"
    echo "export SFTP_USER=$SFTP_USER" >> /root/.envrc
fi

#--- please do not edit below this file ---#

SSHD_CONFIG='/etc/ssh/sshd_config'

if [ ! -d "/home/${BASE_NAME}" ]; then
    useradd --shell=/bin/bash -m --home-dir /home/${BASE_NAME} $SFTP_USER

    groupadd ${BASE_NAME}

    # "web" is meant for SFTP only user/s
    gpasswd -a $SFTP_USER ${BASE_NAME} &> /dev/null

    chown root:root /home/${BASE_NAME}
    chmod 755 /home/${BASE_NAME}

    #-- allow the user to login to the server --#
    # older way of doing things by appending it to AllowUsers directive
    # if ! grep "$SFTP_USER" ${SSHD_CONFIG} &> /dev/null ; then
      # sed -i '/AllowUsers/ s/$/ '$SFTP_USER'/' ${SSHD_CONFIG}
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
    # usermod -a -G sshusers ${SFTP_USER}

    # if the text 'match group ${BASE_NAME}' isn't found, then
    # insert it only once
    if ! grep -q "Match group ${BASE_NAME}" "${SSHD_CONFIG}" &> /dev/null ; then
        # remove the existing subsystem
        sed -i 's/^Subsystem/### &/' ${SSHD_CONFIG}

        # add new subsystem
    echo "
        # setup internal SFTP
        Subsystem sftp internal-sftp
            Match group ${BASE_NAME}
            ChrootDirectory %h
            PasswordAuthentication yes
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
        # echo "See the logfile ${log_file} for details of the error"
        # echo 'Exiting pre-maturely'
        # exit 1
    # else
        # echo 'Cool. Things seem fine.'
        echo 'Restarting SSH daemon...'
        systemctl restart sshd &> /dev/null
        if [ "$?" != 0 ]; then
            echo 'Something went wrong while creating SFTP user! See below...'; echo; echo;
            systemctl status sshd
        else
            echo ...SSH daemon restarted!
        fi
    # fi # end of sshd -t check

    WP_SFTP_PASS=$(pwgen -cns 12 1)
    echo "export WP_SFTP_PASS=$WP_SFTP_PASS" >> /root/.envrc

    echo "$SFTP_USER:$WP_SFTP_PASS" | chpasswd
else
    echo "the default directory /home/${BASE_NAME} already exists!"
    # exit 1
fi # end of if ! -d "/home/${BASE_NAME}" - whoops

echo ...done setting up SFTP user!
