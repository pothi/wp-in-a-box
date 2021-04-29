#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

local_wp_in_a_box_repo=/root/git/wp-in-a-box
source ${HOME}/.envrc

# Common shell related configs for root user
cp $local_wp_in_a_box_repo/snippets/linux/common-aliases-envvars ~/.config/
source ~/.config/common-aliases-envvars

if ! grep -qw common-aliases.envvars ~/.bashrc ; then
printf "[[ -f ~/.config/common-aliases-envvars ]] && source ~/.config/common-aliases-envvars\n" >> ~/.bashrc
fi

#--- Common for all users ---#
echo Setting up linux tweaks...
echo -----------------------------------------------------------------------------

mkdir -p /etc/skel/{.aws,.cache,.composer,.config/bash,.gnupg,.gsutil,.local/bin,.nano,.npm,.npm-global,.nvm,.selected-editor,.ssh,.well-known,.wp-cli} &> /dev/null
mkdir -p /etc/skel/{backups/{full-backups,db-backups},git,log,scripts,sites,tmp} &> /dev/null

touch /etc/skel/{.bash_history,.gitconfig,.npmrc,.yarnrc,mbox}

# the following creates an issue with nodejs installation using nvm
# but works fine when installed through nodesource.
# for now, let's use nvm based nodejs installation that can be installed on a per-user basis
# echo 'prefix=~/.npm-global' > /etc/skel/.npmrc

chmod 600 /etc/skel/mbox
chmod 700 /etc/skel/.gnupg
chmod 700 /etc/skel/.ssh

cp $local_wp_in_a_box_repo/snippets/common-aliases-envvars /etc/skel/.config/

# ~/.bashrc tweaks
# touch /etc/skel/.bashrc
# if ! grep -q 'direnv' /etc/skel/.bashrc ; then
    # echo 'eval "$(direnv hook bash)"' >> /etc/skel/.bashrc &> /dev/null
# fi

if ! grep -qw common-aliases-envvars /etc/skel/.bashrc ; then
printf " [ -f ~/.config/common-aliases-envvars ] && source ~/.config/common-aliases-envvars " >> /etc/skel/.bashrc
fi

# end of ~/.bashrc tweaks

###--- VIM Tweaks ---###
[ ! -d ~/.vim ] && mkdir ~/.vim
cp -a $local_wp_in_a_box_repo/snippets/vim/* ~/.vim/

# copy only vimrc to normal users
[ ! -d /etc/skel/.vim ] && mkdir /etc/skel/.vim
cp $local_wp_in_a_box_repo/snippets/vim/vimrc ~/.vim/

# [ ! -f /etc/skel/.vim/vimrc ] && touch /etc/skel/.vim/vimrc
# if ! grep -q '" Custom Code - PK' /etc/skel/.vim/vimrc ; then
    # echo '" Custom Code - PK' > /etc/skel/.vim/vimrc
    # echo "set viminfo+=n~/.vim/viminfo" >> /etc/skel/.vim/vimrc
# fi

# Vim related configs
# VIM_VERSION=$(/usr/bin/vim --version | head -1 | awk {'print $5'} | tr -d .)
# sudo cp -a $local_wp_in_a_box_repo/config/vim/* /etc/skel/.vim/
# sudo cat "$local_wp_in_a_box_repo/config/vimrc.local" >> /etc/skel/.vim/vimrc
# sudo sed -i "s/VIM_VERSION/$VIM_VERSION/g" /etc/skel/.vim/vimrc

# sudo cp -a /etc/skel/.vim /root/ &> /dev/null
# sudo cp /etc/skel/.vim/vimrc /root/.vim/

# [ ! -d ${HOME}/.vim ]       && cp -a /etc/skel/.vim ${HOME}/
# [ ! -f ${HOME}/.vim/vimrc ] && cp /etc/skel/.vim/vimrc ${HOME}/.vim

# cp $local_wp_in_a_box_repo/config/vimrc.local /etc/vim/
# cp -a $local_wp_in_a_box_repo/config/vim/* /usr/share/vim/vim${VIM_VERSION}/
# sed -i "s/VIM_VERSION/$VIM_VERSION/g" /etc/vim/vimrc.local

# Clean up
# rm -rf $local_wp_in_a_box_repo/

#--- Tweak SSH config ---#

# disable password authentication
sshd_config_file=/etc/ssh/sshd_config
sed -i -E '/PasswordAuthentication (yes|no)/ s/^#//' $sshd_config_file
# replace only the first occurrance of the text PasswordAuthentication
sed -i '0,/PasswordAuthentication/I s/yes/no/' $sshd_config_file
sed -i '0,/PubkeyAuthentication/I s/no/yes/' $sshd_config_file

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
        echo 'Something went wrong while restarting SSH! See below...'; echo; echo;
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
# entry='vim/plugged'
# if [ -f /etc/.gitignore ] ; then
# if ! $(grep -q "^${entry}$" "/etc/.gitignore") ; then
# printf "
# ref: http://fallengamer.livejournal.com/93321.html
# https://stackoverflow.com/q/1274057/1004587
# basically two methods
# https://stackoverflow.com/a/34511442/1004587
# https://stackoverflow.com/a/44098435/1004587

# vim/plugged
# " >> /etc/.gitignore
# fi # test if entry is found in file
# fi # test if file exists

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

# ref: https://github.com/guard/listen/wiki/Increasing-the-amount-of-inotify-watchers#the-technical-details
# to fix "Error: ENOSPC: System limit for number of file watchers reached" - when running "watch" with gulp, grunt, etc.
file_watchers_limit_sysctl_file='/etc/sysctl.d/60-file-watchers-limit-local.conf'
# create / overwrite and append our custom values in it
printf "fs.inotify.max_user_watches = 524288\n" > $file_watchers_limit_sysctl_file &> /dev/null
sysctl -p $file_watchers_limit_sysctl_file

echo -------------------------------------------------------------------------
echo ... linux tweaks are done.
