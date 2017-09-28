#!/bin/bash

# post install script for Ubuntu

add-apt-repository ppa:certbot/certbot -y
DEBIAN_FRONTEND=noninteractive apt-get update -q -y
DEBIAN_FRONTEND=noninteractive apt-get install certbot -q -y
