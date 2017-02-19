#!/bin/bash

# get the source from Github
LTREPO=https://github.com/pothi/wp-in-a-box
echo 'Downloading Linux Tweaks from Github repo at '$LTREPO

rm -rf /root/ltweaks &> /dev/null
git clone $LTREPO /root/ltweaks

# Common shell related configs
cp /root/ltweaks/config/custom_aliases.sh /etc/profile.d/
source /root/ltweaks/config/custom_aliases.sh

cp /root/ltweaks/config/custom_exports.sh /etc/profile.d/
source /root/ltweaks/config/custom_exports.sh

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
# cp /etc/skel/.zshrc /root/
cp /etc/skel/.vimrc /root/

# touch /etc/skel/.zshrc
# if ! grep '# Custom Code - PK' /etc/skel/.zshrc ; then
	# echo '# Custom Code - PK' > /etc/skel/.zshrc
	# echo 'HISTFILE=~/log/zsh_history' >> /etc/skel/.zshrc
	# echo 'export EDITOR=vim' >> /etc/skel/.zshrc
	# echo 'export VISUAL=vim' >> /etc/skel/.zshrc
# fi

### Change Shell
# echo 'Changing shell for root to ZSH'
# chsh --shell /usr/bin/zsh
# For ZSH
# cp /root/ltweaks/zprofile /etc/zsh/zprofile
# source /root/ltweaks/zprofile
# cp /root/ltweaks/zshrc /etc/zsh/zshrc
# source /root/ltweaks/zshrc

# Vim related configs
cp /root/ltweaks/config/vimrc.local /etc/vim/
cp -a /root/ltweaks/config/vim/* /usr/share/vim/vim74/

# Misc files
cp /root/ltweaks/config/gitconfig /etc/gitconfig
# the following will be removed in a future version
# cp /root/ltweaks/tmux.conf /etc/tmux.conf

# Clean up
rm -rf /root/ltweaks/

#--- Tweak Logwatch ---#
mv /etc/cron.daily/00logwatch /etc/cron.weekly/00logwatch &> /dev/null
if [ $? != 0 ]; then
	echo 'Error tweaking logwatch'
fi

LOGWATCH_CONF=/etc/logwatch/conf/logwatch.conf
touch $LOGWATCH_CONF
echo 'Range = "between -7 days and -1 days"' >> $LOGWATCH_CONF
echo 'Details = High' >> $LOGWATCH_CONF
if [ $EMAIL != '' ]; then
    echo "mailto = $EMAIL" >> $LOGWATCH_CONF
fi

if [ $WP_DOMAIN != '' ]; then
    echo "MailFrom = logwatch@$WP_DOMAIN" >> $LOGWATCH_CONF
    echo "Subject = 'Weekly log from $WP_DOMAIN server'" >> $LOGWATCH_CONF
fi

echo 'Linux tweaks are done.'
