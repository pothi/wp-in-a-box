#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

export DEBIAN_FRONTEND=noninteractive

echo 'Setting up ufw...'

package="ufw"
if dpkg-query -s $package &> /dev/null
then
    echo "$package is already installed"
else
    printf '%-72s' "Installing ${package}..."
    apt-get -qq install $package &> /dev/null
    echo done.
fi

# UFW
ufw default deny incoming

ufw allow 22
ufw allow 80
ufw allow 443
ufw limit ssh comment 'Rate limit for SSH server'

ufw --force enable
if [ $? != 0 ]; then
    echo 'Error setting up firewall'
fi

echo "... done setting up UFW!"
