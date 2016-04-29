### custom exports by pothi @ tinywp.com

# import global zshrc
if [ -f /etc/zsh/zshrc ]; then
    . /etc/zsh/zshrc
fi

# for grep to output with colors
# export GREP_OPTIONS='--color=always'

# for visudo, svn and others
export EDITOR=vi
export VISUAL=vi

# cursor position fix in history - http://www.mgoff.in/2012/05/09/zsh-command-history-cursor-at-the-end-of-the-line/
unsetopt global_rcs

### end of custom exports by pothi ###

