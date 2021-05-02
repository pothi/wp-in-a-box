#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# what's done here

# variables


# Variables - you may send these as command line options
# dev_user

local_wp_in_a_box_repo=/root/git/wp-in-a-box
. /root/.envrc

echo 'Creating a "web developer" user to login via SFTP...'

dev_user=${DEV_USER:-""}
if [ "$dev_user" == "" ]; then
    # create SFTP username automatically
    dev_user="dev_user_$(pwgen -Av 4 1)"
    echo "export DEV_USER=$dev_user" >> /root/.envrc
fi

home_basename=$(echo $dev_user | awk -F _ '{print $1}')

#--- please do not edit below this file ---#

function configure_disk_usage_alert () {
    [ ! -f /home/${home_basename}/scripts/disk-usage-alert.sh ] && wget -O /home/${home_basename}/scripts/disk-usage-alert.sh https://github.com/pothi/snippets/raw/master/disk-usage-alert.sh
    chown $dev_user:$dev_user /home/${home_basename}/scripts/disk-usage-alert.sh
    chmod +x /home/${home_basename}/scripts/disk-usage-alert.sh

    #--- cron for disk-usage-alert ---#
    crontab -l | grep -qw disk-usage-alert
    if [ "$?" -ne "0" ]; then
        ( crontab -l; echo '@daily ~/scripts/disk-usage-alert.sh &> /dev/null' ) | crontab -
    fi
}

SSHD_CONFIG='/etc/ssh/sshd_config'

if [ ! -d "/home/${home_basename}" ]; then
    useradd --shell=/bin/bash -m --home-dir /home/${home_basename} $dev_user

    # groupadd ${home_basename}

    # "web" is meant for SFTP only user/s
    gpasswd -a $dev_user ${home_basename} &> /dev/null

    chown root:root /home/${home_basename}
    chmod 755 /home/${home_basename}

    #-- allow the user to login to the server --#
    # older way of doing things by appending it to AllowUsers directive
    # if ! grep "$dev_user" ${SSHD_CONFIG} &> /dev/null ; then
      # sed -i '/AllowUsers/ s/$/ '$dev_user'/' ${SSHD_CONFIG}
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
    # usermod -a -G sshusers ${dev_user}

    # if the text 'match group ${home_basename}' isn't found, then
    # insert it only once
    if ! grep -q "Match group ${home_basename}" "${SSHD_CONFIG}" &> /dev/null ; then
        # remove the existing subsystem
        sed -i 's/^Subsystem/### &/' ${SSHD_CONFIG}

        # add new subsystem
    echo "
        # setup internal SFTP
        Subsystem sftp internal-sftp
            Match group ${home_basename}
            ChrootDirectory %h
            PasswordAuthentication yes
            X11Forwarding no
            AllowTcpForwarding no
            ForceCommand internal-sftp
        " >> ${SSHD_CONFIG}

    fi # /Match group ${home_basename}

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

else
    echo "the default directory /home/${home_basename} already exists!"
    # exit 1
fi # end of if ! -d "/home/${home_basename}" - whoops

dev_pass=${DEV_PASS:-""}
if [ "$dev_pass" == "" ]; then
    dev_pass=$(pwgen -cns 12 1)
    echo "export DEV_PASS=$dev_pass" >> /root/.envrc

    echo "$dev_user:$dev_pass" | chpasswd
fi

# cp $local_wp_in_a_box_repo/.envrc-user-sample /home/${home_basename}/.envrc
# chown $dev_user:$dev_user /home/${home_basename}/.envrc

# configure_disk_usage_alert

# cd $local_wp_in_a_box_repo/scripts/ &> /dev/null
# sudo -H -u $dev_user bash nvm-nodejs.sh
# cd - &> /dev/null

# download scripts to backup wordpress
echo 'Downloading backup scripts...'
FULL_BACKUP_URL=https://raw.githubusercontent.com/pothi/backup-wordpress/master/full-backup.sh
DB_BACKUP_URL=https://raw.githubusercontent.com/pothi/backup-wordpress/master/db-backup.sh
FILES_BACKUP_URL=https://raw.githubusercontent.com/pothi/backup-wordpress/master/files-backup-without-uploads.sh
[ ! -s ~/scripts/full-backup.sh ] && wget -q -O ~/scripts/full-backup.sh $FULL_BACKUP_URL
[ ! -s ~/scripts/db-backup.sh ] && wget -q -O ~/scripts/db-backup.sh $DB_BACKUP_URL
[ ! -s ~/scripts/files-backup-without-uploads.sh ] && wget -q -O ~/scripts/files-backup-without-uploads.sh $FILES_BACKUP_URL
echo '... done'

# make scripts executable to all
chmod +x ~/scripts/*.sh

echo ...done setting up SFTP username for Web Developer!
