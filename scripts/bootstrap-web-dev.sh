#!/usr/bin/env sh

# Download common-aliases-envvars and insert into ~/.bashrc
# Download backup scripts.
# Download wp-cli and install it locally.
# Install AWS CLI if needed.
# Install GCloud utils if needed.

# Download backup scripts
echo 'Downloading backup scripts...'
FULL_BACKUP_URL=https://raw.githubusercontent.com/pothi/backup-wordpress/master/full-backup.sh
DB_BACKUP_URL=https://raw.githubusercontent.com/pothi/backup-wordpress/master/db-backup.sh
FILES_BACKUP_URL=https://raw.githubusercontent.com/pothi/backup-wordpress/master/files-backup-without-uploads.sh
[ ! -s ~/scripts/full-backup.sh ] && wget -q -O ~/scripts/full-backup.sh $FULL_BACKUP_URL
[ ! -s ~/scripts/db-backup.sh ] && wget -q -O ~/scripts/db-backup.sh $DB_BACKUP_URL
[ ! -s ~/scripts/files-backup-without-uploads.sh ] && wget -q -O ~/scripts/files-backup-without-uploads.sh $FILES_BACKUP_URL
echo '... done'

[ ! -d ~/.config ] && mkdir ~/.config

[ ! -s ~/.config/common-aliases-envvars ] && wget -q -O ~/.config/common-aliases-envvars https://github.com/pothi/snippets/raw/master/linux/common-aliases-envvars

[ ! grep -q common-aliases-envvars ~/.bashrc ] && echo '[[ -f ~/.config/common-aliases-envvars ]] && source ~/.config/common-aliases-envvars' >> ~/.bashrc
[ ! grep -q custom-aliases-envvars ~/.bashrc ] && echo '[[ -f ~/.config/custom-aliases-envvars ]] && source ~/.config/custom-aliases-envvars' >> ~/.bashrc

