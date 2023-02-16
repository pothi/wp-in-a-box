#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# export DEBIAN_FRONTEND=noninteractive

# what's done here

# variables

#--- cron tweaks ---#
#--- separate cron log ---#
# if ! grep -q '# Log cron stuff' /etc/rsyslog.conf ; then
    # echo '# Log cron stuff' > /etc/rsyslog.conf
    # echo "cron.*    /var/log/cron" >> /etc/rsyslog.conf
# fi
# sed -i -e 's/^#cron.*/cron.*/' /etc/rsyslog.d/50-default.conf
echo 'cron.*  /var/log/cron.log' > /etc/rsyslog.d/90-cron.conf

#- log only errors -#
# the following solution may not work in the future, as /etc/default/cron is being deprecated!
# sed -i -e 's/^#EXTRA_OPTS=""$/EXTRA_OPTS=""/' -e 's/^EXTRA_OPTS=""$/EXTRA_OPTS="-L 0"/' /etc/default/cron

systemctl restart syslog
systemctl restart cron


