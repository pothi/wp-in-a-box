#!/bin/bash

# Common shell related configs
cp $LOCAL_WPINABOX_REPO/config/custom_aliases.sh /etc/profile.d/
source $LOCAL_WPINABOX_REPO/config/custom_aliases.sh

cp $LOCAL_WPINABOX_REPO/config/custom_exports.sh /etc/profile.d/
source $LOCAL_WPINABOX_REPO/config/custom_exports.sh

#--- Common for all users ---#
echo 'Setting up skel'

touch /etc/skel/.bashrc &> /dev/null
if ! grep 'direnv' /etc/skel/.bashrc &> /dev/null ; then
    echo 'eval "$(direnv hook bash)"' >> /etc/skel/.bashrc &> /dev/null
fi

mkdir /etc/skel/.vim &> /dev/null
touch /etc/skel/.vimrc &> /dev/null
if ! grep '" Custom Code - PK' /etc/skel/.vimrc &> /dev/null ; then
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

# Misc files
cp $LOCAL_WPINABOX_REPO/config/gitconfig /etc/gitconfig

# Clean up
# rm -rf $LOCAL_WPINABOX_REPO/

#--- Tweak SSH config ---#

# disable password authentication for root
# make sure that SSH user has been created
passwd -l root

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


#--- Put /etc/ under version control ---#
cd /etc
echo "
# ref: http://fallengamer.livejournal.com/93321.html \
# https://stackoverflow.com/q/1274057/1004587 \
 \
# basically two methods \
# https://stackoverflow.com/a/34511442/1004587 \
# https://stackoverflow.com/a/44098435/1004587 \
 \
vim/plugged" >> /etc/.gitignore

git init
git add .
git commit -m 'First commit'
cd -

#--- Misc Tweaks ---#
sed -i 's/^#\(startup_message off\)$/\1/' /etc/screenrc

echo 'Linux tweaks are done.'
