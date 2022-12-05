#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

export DEBIAN_FRONTEND=noninteractive

# what's done here

# variables

# todo: update via cron

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
    sudo /tmp/aws/install --install-dir /usr/local/aws-cli --bin-dir /usr/local/bin &> /dev/null # for installation
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
    [ -d /usr/local/aws ] && sudo rm -rf /usr/local/aws
    [ -f /usr/local/bin/aws ] && sudo rm /usr/local/bin/aws

    # for version #2
    # ref: https://docs.aws.amazon.com/cli/latest/userguide/install-bundle.html
    curl --silent "https://awscli.amazonaws.com/awscli-exe-linux-$(arch).zip" -o "/tmp/awscliv2.zip"
    unzip -qq -d /tmp/ /tmp/awscliv2.zip
    sudo /tmp/aws/install --install-dir /usr/local/aws-cli --bin-dir /usr/local/bin --update &> /dev/null

    # cleanup
    rm /tmp/awscliv2.zip
    rm -rf /tmp/aws

    echo done.
}

which aws && update_awscli
which aws || install_awscli
