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

echo 'Linux tweaks are done.'
