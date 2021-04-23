#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

# what's done here

# variables


# Variables - you may send these as command line options
# web_developer_username

source /root/.envrc

echo 'Creating a "web developer" user to login via SFTP...'

if [ "$web_developer_username" == "" ]; then
    # create SFTP username automatically
    web_developer_username="sftp_web_$(pwgen -A 8 1)"
    echo "export web_developer_username=$web_developer_username" >> /root/.envrc
fi

#--- please do not edit below this file ---#

function configure_disk_usage_alert () {
    [ ! -f /home/${BASE_NAME}/scripts/disk-usage-alert.sh ] && wget -O /home/${BASE_NAME}/scripts/disk-usage-alert.sh https://github.com/pothi/snippets/raw/master/disk-usage-alert.sh
    chown $web_developer_username:$web_developer_username /home/${BASE_NAME}/scripts/disk-usage-alert.sh
    chmod +x /home/${BASE_NAME}/scripts/disk-usage-alert.sh

    #--- cron for disk-usage-alert ---#
    crontab -l | grep -qw disk-usage-alert
    if [ "$?" -ne "0" ]; then
        ( crontab -l; echo '@daily ~/scripts/disk-usage-alert.sh &> /dev/null' ) | crontab -
    fi
}

SSHD_CONFIG='/etc/ssh/sshd_config'

if [ ! -d "/home/${BASE_NAME}" ]; then
    useradd --shell=/bin/bash -m --home-dir /home/${BASE_NAME} $web_developer_username

    groupadd ${BASE_NAME}

    # "web" is meant for SFTP only user/s
    gpasswd -a $web_developer_username ${BASE_NAME} &> /dev/null

    chown root:root /home/${BASE_NAME}
    chmod 755 /home/${BASE_NAME}

    #-- allow the user to login to the server --#
    # older way of doing things by appending it to AllowUsers directive
    # if ! grep "$web_developer_username" ${SSHD_CONFIG} &> /dev/null ; then
      # sed -i '/AllowUsers/ s/$/ '$web_developer_username'/' ${SSHD_CONFIG}
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
    # usermod -a -G sshusers ${web_developer_username}

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

    web_developer_password=$(pwgen -cns 12 1)
    echo "export web_developer_password=$web_developer_password" >> /root/.envrc

    echo "$web_developer_username:$web_developer_password" | chpasswd
else
    echo "the default directory /home/${BASE_NAME} already exists!"
    # exit 1
fi # end of if ! -d "/home/${BASE_NAME}" - whoops

cp $local_wp_in_a_box_repo/.envrc-user-sample /home/${BASE_NAME}/.envrc
chown $web_developer_username:$web_developer_username /home/${BASE_NAME}/.envrc

# configure_disk_usage_alert

# cd $local_wp_in_a_box_repo/scripts/ &> /dev/null
# sudo -H -u $web_developer_username bash nvm-nodejs.sh
# cd - &> /dev/null

echo ...done setting up SFTP username for Web Developer!
