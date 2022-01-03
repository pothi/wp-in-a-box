#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

export DEBIAN_FRONTEND=noninteractive

# what's done here
# fine-tune low end servers.

# variables

# Journald tweak - limit disk usage.
# ref: https://blog.tuxclouds.org/posts/journalctl-clean-up-and-tricks/
cp /etc/systemd/journald.conf ~/backups/
sed -i 's/^#\?SystemMaxUse=.*/SystemMaxUse=512M/' /etc/systemd/journald.conf
