#!/bin/bash

echo 'Install optional packages. It may take some time to complete...'
optional_packages="acl \
    postfix \
    logwatch \
    mailutils \
    redis-server \
    letsencrypt \
    pwgen \
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
    echo -n "Installing ${package}..."
    DEBIAN_FRONTEND=noninteractive apt-get -qq install $package
    echo " done."
done
echo "Done installing optional packages."

