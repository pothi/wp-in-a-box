#!/bin/bash

mkdir -p ~/.config/bash &> /dev/null

# Common shell related configs for root user
cp $LOCAL_WPINABOX_REPO/config/checks.sh ~/.config/
cp $LOCAL_WPINABOX_REPO/config/common-aliases.sh ~/.config/bash/
cp $LOCAL_WPINABOX_REPO/config/common-exports.sh ~/.config/bash/
source ~/.config/checks.sh
source ~/.config/bash/common-aliases.sh
source ~/.config/bash/common-exports.sh

if ! grep -qw checks.sh ~/.bashrc ; then
printf "[[ -f ~/.config/checks.sh ]] && source ~/.config/checks.sh\n" >> ~/.bashrc
fi

if ! grep -qw common-exports.sh ~/.bashrc ; then
printf "[[ -f ~/.config/bash/common-exports.sh ]] && source ~/.config/bash/common-exports.sh\n" >> ~/.bashrc
fi

if ! grep -qw common-aliases.sh ~/.bashrc ; then
printf "[[ -f ~/.config/bash/common-aliases.sh ]] && source ~/.config/bash/common-aliases.sh\n" >> ~/.bashrc
fi

#--- Common for all users ---#
echo 'Setting up skel...'

mkdir -p /etc/skel/{.aws,.composer,.config,.gsutil,.nano,.npm,.npm-global,.selected-editor,.ssh,.well-known,.wp-cli} &> /dev/null
mkdir -p /etc/skel/{backups,log,scripts,sites,tmp} &> /dev/null
mkdir -p /etc/skel/backups/{files,databases} &> /dev/null
mkdir -p /etc/skel/.config/bash &> /dev/null

touch /etc/skel/{.bash_history,.npmrc,.yarnrc,mbox}
chmod 600 /etc/skel/mbox &> /dev/null

mkdir /etc/skel/.config &> /dev/null
cp $LOCAL_WPINABOX_REPO/config/checks.sh /etc/skel/.config/
cp $LOCAL_WPINABOX_REPO/config/common-aliases.sh /etc/skel/.config/bash/
cp $LOCAL_WPINABOX_REPO/config/common-exports.sh /etc/skel/.config/bash/

# download scripts to backup wordpress
if [ ! -s /etc/skel/scripts/full-backup.sh ]; then
    echo -n 'Downloading full-backup.sh... '
    DB_BACKUP_URL=https://raw.githubusercontent.com/pothi/backup-wordpress/master/full-backup.sh
    wget -q -O /etc/skel/scripts/full-backup.sh $DB_BACKUP_URL
    echo "done."
fi

if [ ! -s /etc/skel/scripts/db-backup.sh ]; then
    echo -n 'Downloading db-backup.sh... '
    DB_BACKUP_URL=https://raw.githubusercontent.com/pothi/backup-wordpress/master/db-backup.sh
    wget -q -O /etc/skel/scripts/db-backup.sh $DB_BACKUP_URL
    echo "done."
fi

if [ ! -s /etc/skel/scripts/files-backup-without-uploads.sh ]; then
    echo -n 'Downloading files-backup-without-uploads.sh... '
    DB_BACKUP_URL=https://raw.githubusercontent.com/pothi/backup-wordpress/master/files-backup-without-uploads.sh
    wget -q -O /etc/skel/scripts/files-backup-without-uploads.sh $DB_BACKUP_URL
    echo "done."
fi

# make scripts executable to all
chmod +x /etc/skel/scripts/*.sh

# ~/.bashrc tweaks
touch /etc/skel/.bashrc
if ! grep -q 'direnv' /etc/skel/.bashrc ; then
    echo 'eval "$(direnv hook bash)"' >> /etc/skel/.bashrc &> /dev/null
fi

if ! grep -qw checks.sh /etc/skel/.bashrc ; then
printf "
if [ -f ~/.config/checks.sh ]; then
    source ~/.config/checks.sh
fi
" >> /etc/skel/.bashrc
fi

if ! grep -qw common-aliases.sh /etc/skel/.bashrc ; then
printf "
if [ -f ~/.config/bash/common-aliases.sh ]; then
    source ~/.config/bash/common-aliases.sh
fi
" >> /etc/skel/.bashrc
fi

if ! grep -qw common-exports.sh /etc/skel/.bashrc ; then
printf "
if [ -f ~/.config/bash/common-exports.sh ]; then
    source ~/.config/bash/common-exports.sh
fi
" >> /etc/skel/.bashrc
fi
# end of ~/.bashrc tweaks


mkdir /etc/skel/.vim &> /dev/null
touch /etc/skel/.vimrc
if ! grep -q '" Custom Code - PK' /etc/skel/.vimrc ; then
    echo '" Custom Code - PK' > /etc/skel/.vimrc
    echo "set viminfo+=n~/.vim/viminfo" >> /etc/skel/.vimrc
fi

# copy the skel info to root
mkdir /root/.vim &> /dev/null
cp /etc/skel/.vimrc /root/

# Vim related configs
VIM_VERSION=$(/usr/bin/vim --version | head -1 | awk {'print $5'} | tr -d .)
cp $LOCAL_WPINABOX_REPO/config/vimrc.local /etc/vim/
cp -a $LOCAL_WPINABOX_REPO/config/vim/* /usr/share/vim/vim${VIM_VERSION}/
sed -i "s/VIM_VERSION/$VIM_VERSION/g" /etc/vim/vimrc.local

# Clean up
# rm -rf $LOCAL_WPINABOX_REPO/

#--- Tweak SSH config ---#

# disable password authentication
SSHD_CONFIG=/etc/ssh/sshd_config
sed -i -E '/PasswordAuthentication (yes|no)/ s/^#//' $SSHD_CONFIG
sed -i '/PasswordAuthentication/I s/yes/no/' $SSHD_CONFIG

# echo 'Testing the modified SSH config'
# the following didn't work
# sshd –t
# /usr/sbin/sshd -t
# if [ "$?" != 0 ]; then
    # echo 'Something is messed up in the SSH config file'
    # echo 'Please re-run after fixing errors'
    # echo "See the logfile ${LOG_FILE} for details of the error"
    # echo 'Exiting pre-maturely'
    # exit 1
# else
    # echo 'Cool. Things seem fine.'
    echo 'Restarting SSH Daemon...'
    systemctl restart sshd &> /dev/null
    if [ "$?" != 0 ]; then
        echo 'Something went wrong while creating SFTP user! See below...'; echo; echo;
        systemctl status sshd
    else
        echo 'SSH Daemon restarted!'
        echo 'WARNING: Try to create another SSH connection from another terminal, just incase...!'
        echo 'Do NOT ignore this warning'
    fi
# fi


#--- Tweak Logwatch ---#
if [ -f /etc/cron.daily/00logwatch ]; then
    mv /etc/cron.daily/00logwatch /etc/cron.weekly/00logwatch &> /dev/null
    if [ $? != 0 ]; then
        echo 'Error tweaking logwatch'
    fi

    LOGWATCH_CONF=/etc/logwatch/conf/logwatch.conf
    touch $LOGWATCH_CONF
    echo 'Range = "between -7 days and -1 days"' >> $LOGWATCH_CONF
    echo 'Details = High' >> $LOGWATCH_CONF
    if [ "$EMAIL" != '' ]; then
        echo "mailto = $EMAIL" >> $LOGWATCH_CONF
    fi

    if [ "$WP_DOMAIN" != '' ]; then
        echo "MailFrom = logwatch@$WP_DOMAIN" >> $LOGWATCH_CONF
        echo "Subject = 'Weekly log from $WP_DOMAIN server'" >> $LOGWATCH_CONF
    fi

fi # test for logwatch cron

#--- Put /etc/ under version control ---#
comment='vim/plugged'
if [ -f /etc/.gitignore ] ; then
if ! $(grep -q "^${comment}$" "/etc/.gitignore") ; then
printf "
# ref: http://fallengamer.livejournal.com/93321.html
# https://stackoverflow.com/q/1274057/1004587
# basically two methods
# https://stackoverflow.com/a/34511442/1004587
# https://stackoverflow.com/a/44098435/1004587

vim/plugged
" >> /etc/.gitignore
fi # test if comment is found in file
fi # test if file exists

#--- Misc Tweaks ---#
sed -i 's/^#\(startup_message off\)$/\1/' /etc/screenrc

#--- setup color for root terminal ---#
rootbashrc=/root/.bashrc
comment='#red_color for root'
if [ -f $rootbashrc ]; then
if ! $(grep -q "^${comment}$" "$rootbashrc") ; then
    printf "\n${comment}\n" >> $rootbashrc
    echo 'PS1="\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u\[\033[01;33m\]@\[\033[01;36m\]\h \[\033[01;33m\]\w \[\033[01;35m\]\$ \[\033[00m\]"' >> $rootbashrc
    printf '\n' >> $rootbashrc
    source $rootbashrc
fi # test if the comment is found in file
fi # test if file exists

echo 'Linux tweaks are done.'
