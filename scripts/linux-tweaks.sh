#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
source /root/.envrc

[ ! -d ~/.config/bash ] && mkdir -p ~/.config/bash

# Common shell related configs for root user
cp $local_wp_in_a_box_repo/config/checks.sh ~/.config/
cp $local_wp_in_a_box_repo/config/common-aliases.sh ~/.config/bash/
cp $local_wp_in_a_box_repo/config/common-exports.sh ~/.config/bash/
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
echo Setting up linux tweaks...
echo -----------------------------------------------------------------------------

mkdir -p /etc/skel/{.aws,.cache,.composer,.config,.gsutil,.nano,.npm,.npm-global,.selected-editor,.ssh,.well-known,.wp-cli} &> /dev/null
mkdir -p /etc/skel/{backups,log,scripts,sites,tmp} &> /dev/null
mkdir -p /etc/skel/backups/{files,databases} &> /dev/null
mkdir -p /etc/skel/.config/bash &> /dev/null

touch /etc/skel/{.bash_history,.npmrc,.yarnrc,mbox}
chmod 600 /etc/skel/mbox &> /dev/null

mkdir /etc/skel/.config &> /dev/null
cp $local_wp_in_a_box_repo/config/checks.sh /etc/skel/.config/
cp $local_wp_in_a_box_repo/config/common-aliases.sh /etc/skel/.config/bash/
cp $local_wp_in_a_box_repo/config/common-exports.sh /etc/skel/.config/bash/

# download scripts to backup wordpress
if [ ! -s /etc/skel/scripts/full-backup.sh ]; then
    printf '%-72s' "Downloading full-backup.sh"
    DB_BACKUP_URL=https://raw.githubusercontent.com/pothi/backup-wordpress/master/full-backup.sh
    wget -q -O /etc/skel/scripts/full-backup.sh $DB_BACKUP_URL
    echo done.
fi

if [ ! -s /etc/skel/scripts/db-backup.sh ]; then
    printf '%-72s' "Downloading db-backup.sh"
    DB_BACKUP_URL=https://raw.githubusercontent.com/pothi/backup-wordpress/master/db-backup.sh
    wget -q -O /etc/skel/scripts/db-backup.sh $DB_BACKUP_URL
    echo done.
fi

if [ ! -s /etc/skel/scripts/files-backup-without-uploads.sh ]; then
    printf '%-72s' "Downloading files-backup-without-uploads.sh"
    DB_BACKUP_URL=https://raw.githubusercontent.com/pothi/backup-wordpress/master/files-backup-without-uploads.sh
    wget -q -O /etc/skel/scripts/files-backup-without-uploads.sh $DB_BACKUP_URL
    echo done.
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
cp $local_wp_in_a_box_repo/config/vimrc.local /etc/vim/
cp -a $local_wp_in_a_box_repo/config/vim/* /usr/share/vim/vim${VIM_VERSION}/
sed -i "s/VIM_VERSION/$VIM_VERSION/g" /etc/vim/vimrc.local

# Clean up
# rm -rf $local_wp_in_a_box_repo/

#--- Tweak SSH config ---#

# disable password authentication
sshd_config_file=/etc/ssh/sshd_config
sed -i -E '/PasswordAuthentication (yes|no)/ s/^#//' $sshd_config_file
# replace only the first occurrance of the text PasswordAuthentication
sed -i '0,/PasswordAuthentication/I s/yes/no/' $sshd_config_file

# echo 'Testing the modified SSH config'
# the following didn't work
# sshd –t
# /usr/sbin/sshd -t
# if [ "$?" != 0 ]; then
    # echo 'Something is messed up in the SSH config file'
    # echo 'Please re-run after fixing errors'
    # echo "See the logfile ${log_file} for details of the error"
    # echo 'Exiting pre-maturely'
    # exit 1
# else
    # echo 'Cool. Things seem fine.'
    # echo "Restarting SSH daemon..."
    printf '%-72s' "Restarting SSH daemon..."
    systemctl restart sshd &> /dev/null
    if [ $? -ne 0 ]; then
        echo 'Something went wrong while creating SFTP user! See below...'; echo; echo;
        systemctl status sshd
    else
        # echo '... SSH daemon restarted!'
        echo done.
    fi
# fi


#--- Tweak Logwatch ---#
if [ -f /etc/cron.daily/00logwatch ]; then
    mv /etc/cron.daily/00logwatch /etc/cron.weekly/00logwatch &> /dev/null
    check_result $? 'Error moving logwatch cron file'

    logwatch_conf_file=/etc/logwatch/conf/logwatch.conf
    touch $logwatch_conf_file
    echo 'Range = "between -7 days and -1 days"' >> $logwatch_conf_file
    echo 'Details = High' >> $logwatch_conf_file
    if [ ! -z "$EMAIL" ]; then
        echo "mailto = $EMAIL" >> $logwatch_conf_file
    fi

    if [ ! -z "$WP_DOMAIN" ]; then
        echo "MailFrom = logwatch@$WP_DOMAIN" >> $logwatch_conf_file
        echo "Subject = 'Weekly log from $WP_DOMAIN server'" >> $logwatch_conf_file
    fi

fi # test for logwatch cron

#--- Put /etc/ under version control ---#
entry='vim/plugged'
if [ -f /etc/.gitignore ] ; then
if ! $(grep -q "^${entry}$" "/etc/.gitignore") ; then
printf "
# ref: http://fallengamer.livejournal.com/93321.html
# https://stackoverflow.com/q/1274057/1004587
# basically two methods
# https://stackoverflow.com/a/34511442/1004587
# https://stackoverflow.com/a/44098435/1004587

vim/plugged
" >> /etc/.gitignore
fi # test if entry is found in file
fi # test if file exists

#--- Misc Tweaks ---#
sed -i 's/^#\(startup_message off\)$/\1/' /etc/screenrc

#--- setup color for root terminal ---#
rootbashrc=/root/.bashrc
entry='#red_color for root'
if [ -f $rootbashrc ]; then
if ! $(grep -q "^${entry}$" "$rootbashrc") ; then
    printf "\n${entry}\n" >> $rootbashrc
    echo 'PS1="\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u\[\033[01;33m\]@\[\033[01;36m\]\h \[\033[01;33m\]\w \[\033[01;35m\]\$ \[\033[00m\]"' >> $rootbashrc
    printf '\n' >> $rootbashrc
    source $rootbashrc
fi # test if the entry is found in file
fi # test if file exists

echo -------------------------------------------------------------------------
echo ... linux tweaks are done.
