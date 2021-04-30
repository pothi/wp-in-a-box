#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# what's done here
# - PMA auto update script is downloaded and executed.
# - A cron tab entry is in place to update PMA using the auto update script.

# variables


mkdir ~/{phpmyadmin,log,scripts} &> /dev/null

curl -sL https://github.com/pothi/snippets/raw/master/pma-auto-update.sh -o ~/scripts/pma-auto-update.sh
chmod +x ~/scripts/pma-auto-update.sh

~/scripts/pma-auto-update.sh

# setup cron to self-update phpmyadmin
if ! $(crontab -l | grep -qw phpmyadmin) ; then
    ( crontab -l; echo; echo "# auto-update phpmyadmin - nightly" ) | crontab -
    ( crontab -l; echo '@daily ~/scripts/pma-auto-update.sh &> /dev/null' ) | crontab -
fi



