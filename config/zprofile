### custom exports by pothi @ customwp.com

# import global zshrc
if [ -f /etc/zsh/zshrc ]; then
    . /etc/zsh/zshrc
fi

# cursor position fix in history - http://www.mgoff.in/2012/05/09/zsh-command-history-cursor-at-the-end-of-the-line/
unsetopt global_rcs

### end of custom exports by pothi ###

# import global custom exports
if [ -f /etc/profile.d/custom_exports.sh ]; then
    source /etc/profile.d/custom_exports.sh
fi

# import local custom exports
if [ -f $HOME/.config/custom_exports.sh ]; then
    source $HOME/.config/custom_exports.sh
fi

