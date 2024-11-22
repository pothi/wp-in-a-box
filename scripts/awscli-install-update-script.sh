#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

# set -x

# to capture non-zero exit code in the pipeline
set -o pipefail

# what's done here
# install aws cli depending on user (normal user or root)
# if root, install aws cli in /usr/local/{aws-cli,bin}
# if normal user, install it in ~/.local/{aws-cli,bin}

# variables
# none

# ToDo: update via cron

# check root user
# https://stackoverflow.com/a/52586842/1004587
# also see https://stackoverflow.com/q/3522341/1004587
is_user_root () { [ "${EUID:-$(id -u)}" -eq 0 ]; }
if is_user_root; then
    # echo 'You must be root or user with sudo privilege to run this script. Exiting now.'; exit 1;
    InstallDir=/usr/local/aws-cli
    BinDir=/usr/local/bin
else
    InstallDir=~/.local/aws-cli
    BinDir=~/.local/bin
    # attempt to create InstallDir and BinDir
    [ -d $InstallDir ] || mkdir -p $InstallDir
    if [ "$?" -ne "0" ]; then
        echo "InstallDir is not found at $InstallDir. This script can't create it, either!"
        echo 'You may create it manually and re-run this script.'
        exit 1
    fi
    [ -d $BinDir ] || mkdir -p $BinDir
    if [ "$?" -ne "0" ]; then
        echo "BinDir is not found at $BinDir. This script can't create it, either!"
        echo 'You may create it manually and re-run this script.'
        exit 1
    fi
fi

export PATH=~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

function install_awscli {
    #----- install AWS cli -----#
    printf '%-72s' "Installing awscli..."

    # for version #1
    # TODO: Update this function to install version #2
    # see - https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html

    # version #1
    # curl --silent "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "/tmp/awscli-bundle.zip"
    # unzip -qq -d /tmp/ /tmp/awscli-bundle.zip
    # sudo /tmp/awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws &> /dev/null

    # for version #2
    # ref: https://docs.aws.amazon.com/cli/latest/userguide/install-bundle.html
    curl --silent "https://awscli.amazonaws.com/awscli-exe-linux-$(arch).zip" -o "/tmp/awscliv2.zip"
    unzip -qq -d /tmp/ /tmp/awscliv2.zip
    /tmp/aws/install --install-dir $InstallDir --bin-dir $BinDir &> /dev/null # for installation
    if [ "$?" != "0" ]; then
        echo "Error installing aws cli!"
    fi

    # cleanup
    rm /tmp/awscliv2.zip
    rm -rf /tmp/aws

    # version #1
    # rm /tmp/awscli-bundle.zip
    # rm -rf /tmp/awscli-bundle
    echo done.
}

function update_awscli {
    #----- install AWS cli -----#
    printf '%-72s' "Updating awscli..."

    # remove the version #1 of aws cli, if exists
    [ -d /usr/local/aws ] && rm -rf /usr/local/aws &> /dev/null
    [ -f /usr/local/bin/aws ] && rm /usr/local/bin/aws &> /dev/null

    # for version #2
    # ref: https://docs.aws.amazon.com/cli/latest/userguide/install-bundle.html
    curl --silent "https://awscli.amazonaws.com/awscli-exe-linux-$(arch).zip" -o "/tmp/awscliv2.zip"
    unzip -qq -d /tmp/ /tmp/awscliv2.zip
    /tmp/aws/install --install-dir $InstallDir --bin-dir $BinDir --update 1> /dev/null
    if [ "$?" != "0" ]; then
        echo "Error installing aws cli!"
    fi

    # cleanup
    rm /tmp/awscliv2.zip
    rm -rf /tmp/aws

    echo done.
}

if [ $(which aws 2> /dev/null) ]; then
    update_awscli
else
    install_awscli
fi
