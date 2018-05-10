#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

echo -n 'Installing certbot... '
apt-get install -qq certbot
echo 'done.'
