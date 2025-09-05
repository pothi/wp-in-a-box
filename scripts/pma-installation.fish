#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# what's done here
# - PMA auto update script is downloaded and executed.
# - A cron tab entry is in place to update PMA using the auto update script.

# variables


mkdir ~/{phpmyadmin,log} &> /dev/null

curl -sL https://github.com/pothi/snippets/raw/main/misc/pma-auto-update.sh -o ~/pma-auto-update.sh
chmod +x ~/pma-auto-update.sh

~/pma-auto-update.sh

# setup cron to self-update phpmyadmin
crontab -l 2>/dev/null | grep -qw phpmyadmin
if test $status -ne 0
    set min $(random 0 59)
    set hour $(random 0 59)
    ( crontab -l; echo; echo "# auto-update phpmyadmin - nightly" ) | crontab -
    ( crontab -l; echo "$min $hour * * * ~/pma-auto-update.sh >/dev/null" ) | crontab -
else
    echo A cron entry is already in place.
end



