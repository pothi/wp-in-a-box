#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# what's done here
# creation of a test user and password.
# adding test user to sftpusers group
# restarting ssh server

# variables
# TEST_USER
# TEST_PASS

source /root/.envrc

echo 'Creating a "test" user to login via SFTP...'

test_user=${TEST_USER:-""}
if [ "$test_user" == "" ]; then
    # create SFTP username automatically
    test_user="test_user_$(pwgen -Av 4 1)"
    echo "export TEST_USER=$test_user" >> /root/.envrc
fi

test_basename=$(echo $test_user | awk -F _ '{print $1}')

#--- please do not edit below this file ---#

if [ ! -d "/home/${test_basename}" ]; then
    useradd --shell=/bin/bash -m --home-dir /home/${test_basename} $test_user

    gpasswd -a $test_user sftpusers

    chown root:root /home/${test_basename}
    chmod 755 /home/${test_basename}

    echo 'Restarting SSH daemon...'
    systemctl restart sshd
    if [ "$?" != 0 ]; then
        echo 'Something went wrong while creating SFTP user! See below...'; echo; echo;
        systemctl status sshd
    else
        echo ...SSH daemon restarted!
    fi

else
    echo "the default directory /home/${test_basename} already exists!"
    # exit 1
fi # end of if ! -d "/home/${test_basename}"

test_pass=${TEST_PASS:-""}
if [ "$test_pass" == "" ]; then
    test_pass=$(pwgen -cns 12 1)
    echo "export TEST_PASS=$test_pass" >> /root/.envrc

    echo "$test_user:$test_pass" | chpasswd
fi

echo ...done setting up SFTP username for test env!

