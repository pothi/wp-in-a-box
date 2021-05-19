#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# what's done here

# variables


# Variables - you may send these as command line options
# wp_user

local_wp_in_a_box_repo=/root/git/wp-in-a-box
. /root/.envrc

echo 'Creating a WP username to login via SFTP...'

wp_user=${WP_USERNAME:-""}
if [ "$wp_user" == "" ]; then
    # create SFTP username automatically
    wp_user="wp_$(pwgen -Av 9 1)"
    echo "export WP_USER=$wp_user" >> /root/.envrc
fi

home_basename=$(echo $wp_user | awk -F _ '{print $1}')

#--- please do not edit below this file ---#

SSHD_CONFIG='/etc/ssh/sshd_config'

if [ ! -d "/home/${home_basename}" ]; then
    useradd --shell=/bin/bash -m --home-dir /home/${home_basename} $wp_user

    groupadd ${home_basename}

    # "wp" is meant for SFTP only user/s
    gpasswd -a $wp_user ${home_basename} &> /dev/null

    chown root:root /home/${home_basename}
    chmod 755 /home/${home_basename}

    #-- allow the user to login to the server --#
    # older way of doing things by appending it to AllowUsers directive
    # if ! grep "$wp_user" ${SSHD_CONFIG} &> /dev/null ; then
      # sed -i '/AllowUsers/ s/$/ '$wp_user'/' ${SSHD_CONFIG}
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
    # usermod -a -G sshusers ${wp_user}

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

wp_pass=${WP_PASSWORD:-""}
if [ "$wp_pass" == "" ]; then
    wp_pass=$(pwgen -cns 12 1)
    echo "export WP_PASSWORD=$wp_pass" >> /root/.envrc

    echo "$wp_user:$wp_pass" | chpasswd
fi

# cd $local_wp_in_a_box_repo/scripts/ &> /dev/null
# sudo -H -u $wp_user bash nvm-nodejs.sh
# cd - &> /dev/null

echo ...done setting up SFTP username for Web Developer!
