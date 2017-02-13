#!/bin/bash

# get the source from Github
LTREPO=https://github.com/pothi/linux-tweaks-deb
echo 'Downloading Linux Tweaks from Github repo at '$LTREPO
rm -rf /root/ltweaks &> /dev/null
git clone $LTREPO /root/ltweaks

# Shell related configs
cp /root/ltweaks/config/custom_aliases.sh/etc/profile.d/
cp /root/ltweaks/config/custom_exports.sh/etc/profile.d/

# cp /root/ltweaks/zprofile /etc/zsh/zprofile
# cp /root/ltweaks/zshrc /etc/zsh/zshrc

# Vim related configs
cp /root/ltweaks/config/vimrc.local /etc/vim/
cp -a /root/ltweaks/config/vim/* /usr/share/vim/vim74/

# Misc files
cp /root/ltweaks/config/gitconfig /etc/gitconfig
# the following will be removed in a future version
# cp /root/ltweaks/tmux.conf /etc/tmux.conf

# Clean up
rm -rf /root/ltweaks/

