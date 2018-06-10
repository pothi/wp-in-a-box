#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

echo 'Install optional packages. It may take some time to complete...'
optional_packages="acl \
    postfix \
    logwatch \
    mailutils \
    redis-server \
    letsencrypt \
    gawk \
    apt-transport-https \
    apache2-utils \
    software-properties-common dirmngr \
    tree \
    debian-goodies \
    uptimed \
    nmap \
    members"

for package in $optional_packages
do  
    printf '%-72s' "Installing ${package}..."
    apt-get -qq install $package
    echo done.
done
echo "... done installing optional packages."

