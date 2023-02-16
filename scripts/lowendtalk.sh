#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

export DEBIAN_FRONTEND=noninteractive
export PATH=~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

# what's done here
# fine-tune low end servers.

# variables
JOURNALD_MAX_MEM=512M

# Journald tweak - limit disk usage.
# ref: https://blog.tuxclouds.org/posts/journalctl-clean-up-and-tricks/
# to reduce the usage
# journalctl --vacuum-size=512M
# verify current disk usage
# journalctl --disk-usage
[ -d /etc/systemd/journald.conf.d ] || mkdir /etc/systemd/journald.conf.d
if [ -f /etc/systemd/journald.conf.d/custom.conf ]; then
    echo -e "[Journal]\nSystemMaxUse=$JOURNALD_MAX_MEM" > /etc/systemd/journald.conf.d/custom.conf
    systemctl restart systemd-journald
fi

# Disable binlog
systemctl stop mysql
echo 'skip-log-bin = true' > /etc/mysql/mysql.conf.d/80-skip-log-bin.conf
systemctl start mysql
# Remove existing log files
rm /var/lib/mysql/binlog.*
