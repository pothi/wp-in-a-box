#!/usr/bin/env sh

# Download common-aliases-envvars and insert into ~/.bashrc
# Configure root-specific ~/.bashrc changes such as terminal color (red for root).
# Configure crontab, such as certbot renewal.
# Configure vim

[ ! -d ~/.config ] && mkdir ~/.config

[ ! -s ~/.config/common-aliases-envvars ] && wget -q -O ~/.config/common-aliases-envvars https://raw.githubusercontent.com/pothi/snippets/main/linux/common-aliases-envvars
. ~/.config/common-aliases-envvars

if ! grep -qw common-aliases.envvars ~/.bashrc ; then
    printf "[[ -f ~/.config/common-aliases-envvars ]] && source ~/.config/common-aliases-envvars\n" >> ~/.bashrc
fi

if ! grep -qF custom-aliases-envvars-custom ~/.bashrc ; then
    echo "[[ -f ~/.config/custom-aliases-envvars-custom ]] && . ~/.config/custom-aliases-envvars-custom" >> ~/.bashrc
fi

###------------------------------ setup color for root terminal ------------------------------###
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

###------------------------------ VIM Tweaks ------------------------------###
#TODO
[ ! -d ~/.vim ] && mkdir ~/.vim
[ ! -d ~/git/snippets ] && {
    git clone -q --depth 1 https://github.com/pothi/snippets ~/git/snippets
    cp -a ~/git/snippets/vim/* ~/.vim/
}

