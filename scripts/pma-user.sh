#!/bin/bash

mkdir ~/{phpmyadmin,log,scripts} &> /dev/null
curl -Ls https://github.com/pothi/linux-bootstrap-snippets/raw/master/pma-auto-update.sh -o ~/scripts/pma-auto-update.sh &> /dev/null
chmod +x ~/scripts/pma-auto-update.sh &> /dev/null
~/scripts/pma-auto-update.sh &> /dev/null

# setup cron to self-update composer
( crontab -l; echo; echo "# auto-update phpmyadmin - nightly" ) | crontab -
( crontab -l; echo '5   5   *   *   *  ~/scripts/pma-auto-update.sh &> /dev/null' ) | crontab -


