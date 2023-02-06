#!/usr/bin/env sh

# Download common-aliases-envvars and insert into ~/.bashrc
# Configure root-specific ~/.bashrc changes such as terminal color (orange or blue for server admin).
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

###------------------------------ setup color for server-admin terminal ------------------------------###
adminbashrc="~/.bashrc"
entry='#color for server admin'
# if [ -f $adminbashrc ]; then
    # if ! $(grep -q "^${entry}$" "$adminbashrc") ; then
        # printf "\n${entry}\n" >> $adminbashrc
	# PS1 taken from Ubuntu Jammy (22.04)
	# echo 'PS1="\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\#"' >> $adminbashrc
        # echo 'PS1="\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;34m\]\u\[\033[01;33m\]@\[\033[01;36m\]\h \[\033[01;33m\]\w \[\033[01;35m\]\$ \[\033[00m\]"' >> $adminbashrc
        # printf '\n' >> $adminbashrc
        # . $adminbashrc
    # fi # test if the entry is found in file
# fi # test if file exists

###------------------------------ VIM Tweaks ------------------------------###

[ ! -d ~/.vim ] && mkdir ~/.vim
[ ! -d ~/git/snippets ] && {
    git clone -q --depth 1 https://github.com/pothi/snippets ~/git/snippets
    cp -a ~/git/snippets/vim/* ~/.vim/
}

