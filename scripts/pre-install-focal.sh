#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# what's done here

# variables


export DEBIAN_FRONTEND=noninteractive
apt-get -qq install python-is-python3 python3-venv > /dev/null
