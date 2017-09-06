#!/bin/bash

PMA_USER=pma

useradd -m $PMA_USER &> /dev/null

sudo -u $PMA_USER bash pma-user.sh &> /dev/null

# TODO
# install and auto-update the default pma database
