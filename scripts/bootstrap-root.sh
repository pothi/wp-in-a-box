#!/usr/bin/env sh

# Download common-aliases-envvars and insert into ~/.bashrc
# Configure root-specific ~/.bashrc changes such as terminal color (red for root).
# Configure crontab, such as certbot renewal.

[ ! -d ~/.config ] && mkdir ~/.config

[ ! -s ~/.config/common-aliases-envvars ] && wget -q -O ~/.config/common-aliases-envvars https://github.com/pothi/snippets/raw/master/linux/common-aliases-envvars

[ ! grep -q common-aliases-envvars ~/.bashrc ] && echo '[[ -f ~/.config/common-aliases-envvars ]] && source ~/.config/common-aliases-envvars' >> ~/.bashrc
[ ! grep -q custom-aliases-envvars ~/.bashrc ] && echo '[[ -f ~/.config/custom-aliases-envvars ]] && source ~/.config/custom-aliases-envvars' >> ~/.bashrc

#--- setup color for root terminal ---#
rootbashrc=/root/.bashrc
entry='#red_color for root'
if [ -f $rootbashrc ]; then
    if ! $(grep -q "^${entry}$" "$rootbashrc") ; then
        printf "\n${entry}\n" >> $rootbashrc
        echo 'PS1="\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u\[\033[01;33m\]@\[\033[01;36m\]\h \[\033[01;33m\]\w \[\033[01;35m\]\$ \[\033[00m\]"' >> $rootbashrc
        printf '\n' >> $rootbashrc
        . $rootbashrc
    fi # test if the entry is found in file
fi # test if file exists

