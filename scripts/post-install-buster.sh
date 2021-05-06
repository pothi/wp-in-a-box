#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# what's done here

# variables

export DEBIAN_FRONTEND=noninteractive

echo Bionic specific changes:
echo ------------------------
echo -n 'Installing certbot... '
apt-get install -qq certbot &> /dev/null

local_wp_in_a_box_repo=/root/git/wp-in-a-box

[ -f "${local_wp_in_a_box_repo}/snippets/ssl/nginx-restart.sh" ] && {
    cp ${local_wp_in_a_box_repo}/snippets/ssl/nginx-restart.sh /etc/letsencrypt/renewal-hooks/deploy/
    chmod +x /etc/letsencrypt/renewal-hooks/deploy/nginx-restart.sh
}

echo 'done.'

