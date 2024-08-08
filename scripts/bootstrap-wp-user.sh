#!/usr/bin/env sh

# Download common-aliases-envvars and insert into ~/.bashrc
# Download backup scripts.
# Configure vim

# optional
#   - Install node.
#   - Download wp-cli and install it locally.
#   - Install AWS CLI if needed.
#   - Install GCloud utils if needed.

# To debug, use any value for "debug", otherwise please leave it empty
debug=

# helper function to exit upon non-zero exit code of a command
# usage some_command; check_result $? 'some_command failed'
if ! $(type 'check_result' 2>/dev/null | grep -q 'function') ; then
    check_result() {
        if [ "$1" -ne 0 ]; then
            echo -e "\nError: $2. Exiting!\n"
            exit "$1"
        fi
    }
fi

[ "$debug" ] && set -x

#-------------------- Download backup scripts --------------------#
[ ! -d ~/scripts ] && mkdir ~/scripts
# Download backup scripts
echo 'Downloading backup scripts...'
FULL_BACKUP_URL=https://github.com/pothi/backup-wordpress/raw/main/full-backup.sh
DB_BACKUP_URL=https://github.com/pothi/backup-wordpress/raw/main/db-backup.sh
FILES_BACKUP_URL=https://github.com/pothi/backup-wordpress/raw/main/files-backup-without-uploads.sh
# cd ~/scripts
# [ ! -s full-backup.sh ] && curl -LSsO $FULL_BACKUP_URL
# [ ! -s db-backup.sh ] && curl -LSsO $DB_BACKUP_URL
# [ ! -s files-backup-without-uploads.sh ] && curl -LSsO $FILES_BACKUP_URL
[ ! -s ~/scripts/full-backup.sh ] && curl -s --output-dir ~/scripts -O $FULL_BACKUP_URL
[ ! -s ~/scripts/db-backup.sh ] && curl -s --output-dir ~/scripts -O $DB_BACKUP_URL
[ ! -s ~/scripts/files-backup-without-uploads.sh ] && curl -s --output-dir ~/scripts -O $FILES_BACKUP_URL
chmod +x ~/scripts/*.sh
# cd - >/dev/null
# echo '... done'

#-------------------- Configure common-aliases-envvars --------------------#
echo 'Tweaking bash config...'
[ ! -d ~/.config ] && mkdir ~/.config

echo >> ~/.bashrc

[ ! -s ~/.config/common-aliases-envvars ] && curl -s --output-dir ~/.config -O https://github.com/pothi/snippets/raw/main/linux/common-aliases-envvars
. ~/.config/common-aliases-envvars

if ! grep -q common-aliases-envvars ~/.bashrc ; then
    echo "[ -f ~/.config/common-aliases-envvars ] && source ~/.config/common-aliases-envvars" >> ~/.bashrc
fi

if ! grep -qF custom-aliases-envvars-custom ~/.bashrc ; then
    echo "[ -f ~/.config/custom-aliases-envvars-custom ] && . ~/.config/custom-aliases-envvars-custom" >> ~/.bashrc
fi

# Load ~/.envrc file if exists
if ! grep -qF envrc ~/.bashrc ; then
    echo "[ -f ~/.envrc ] && . ~/.envrc" >> ~/.bashrc
fi

echo >> ~/.bashrc

#-------------------- Configure VIM --------------------#
echo 'Tweaking VIM config...'
[ ! -d ~/.vim ] && mkdir ~/.vim
[ ! -d ~/git/snippets ] && {
    git clone -q --depth 1 https://github.com/pothi/snippets ~/git/snippets
    cp -a ~/git/snippets/vim/* ~/.vim/
    # run the following only when not debugging!
    if [ ! "$debug" ]; then
        rm -rf ~/git/snippets
        rmdir ~/git &> /dev/null
    fi
}

#-------------------- Install wp-cli --------------------#
# echo 'Installing wp-cli...'
if ! command -v wp >/dev/null; then
    curl -s --output-dir ~/ -O https://github.com/pothi/wp-in-a-box/raw/main/scripts/wpcli-installation.sh
    bash ~/wpcli-installation.sh && rm ~/wpcli-installation.sh
    check_result $? "Could not install wp-cli."
fi

#-------------------- Install aws-cli --------------------#
# echo 'Installing aws-cli...'
if ! command -v aws >/dev/null; then
    curl -s --output-dir ~/ -O https://github.com/pothi/wp-in-a-box/raw/main/scripts/awscli-install-update-script.sh
    bash ~/awscli-install-update-script.sh && rm ~/awscli-install-update-script.sh
    check_result $? "Could not install aws-cli."
fi

#-------------------- Create SSH keys --------------------#
echo 'Creating local SSH keys...'
< /dev/zero ssh-keygen -q -N "" -t ed25519
echo

#-------------------- Bootstrap timers to alert upon auto-reboot --------------------#
# TODO: Might not work if logged-in through root
echo 'Configuring alerts upon auto-reboot...'
if ! command -v aws >/dev/null; then
    curl -s --output-dir ~/ -O https://github.com/pothi/snippets/raw/main/linux/alert-auto-reboot/bootstrap.sh
    bash ~/bootstrap.sh && rm ~/bootstrap.sh
    check_result $? "Could not bootstrap timers to alert upon auto-reboot."
fi

#-------------------- Unused --------------------#
function configure_disk_usage_alert {
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

