#!/usr/bin/env sh

# Download common-aliases-envvars and insert into ~/.bashrc
# Download backup scripts.
# Download wp-cli and install it locally.
# Install AWS CLI if needed.
# Install GCloud utils if needed.

[ ! -d ~/scripts ] && mkdir ~/scripts
# Download backup scripts
echo 'Downloading backup scripts...'
FULL_BACKUP_URL=https://raw.githubusercontent.com/pothi/backup-wordpress/master/full-backup.sh
DB_BACKUP_URL=https://raw.githubusercontent.com/pothi/backup-wordpress/master/db-backup.sh
FILES_BACKUP_URL=https://raw.githubusercontent.com/pothi/backup-wordpress/master/files-backup-without-uploads.sh
cd ~/scripts
[ ! -s full-backup.sh ] && curl -LSsO $FULL_BACKUP_URL
[ ! -s db-backup.sh ] && curl -LSsO $DB_BACKUP_URL
[ ! -s files-backup-without-uploads.sh ] && curl -LSsO $FILES_BACKUP_URL
chmod +x *.sh
cd - 1>/dev/null
echo '... done'

[ ! -d ~/.config ] && mkdir ~/.config

[ ! -s ~/.config/common-aliases-envvars ] && wget -q -O ~/.config/common-aliases-envvars https://github.com/pothi/snippets/raw/master/linux/common-aliases-envvars
. ~/.config/common-aliases-envvars

if ! grep -q common-aliases-envvars ~/.bashrc ; then
    echo '[[ -f ~/.config/common-aliases-envvars ]] && source ~/.config/common-aliases-envvars' >> ~/.bashrc
fi

if ! grep -qF custom-aliases-envvars-custom ~/.bashrc ; then
    echo "[[ -f ~/.config/custom-aliases-envvars-custom ]] && . ~/.config/custom-aliases-envvars-custom" >> ~/.bashrc
fi

function configure_disk_usage_alert () {
    [ ! -f /home/${home_basename}/scripts/disk-usage-alert.sh ] && wget -O /home/${home_basename}/scripts/disk-usage-alert.sh https://github.com/pothi/snippets/raw/master/disk-usage-alert.sh
    chown $wp_user:$wp_user /home/${home_basename}/scripts/disk-usage-alert.sh
    chmod +x /home/${home_basename}/scripts/disk-usage-alert.sh

    #--- cron for disk-usage-alert ---#
    crontab -l | grep -qw disk-usage-alert
    if [ "$?" -ne "0" ]; then
        ( crontab -l; echo '@daily ~/scripts/disk-usage-alert.sh &> /dev/null' ) | crontab -
    fi
}
# configure_disk_usage_alert

