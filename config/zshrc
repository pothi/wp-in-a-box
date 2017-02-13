# Set default key bindings to VIM, if you prefer!
# bindkey -v

# Set default theme - walters
autoload -U promptinit
promptinit
prompt walters
setopt PROMPT_SUBST
export PROMPT="%B%(?..[%?] )%b%n@%U$(hostname -f | awk -F . '{print $2"."$3}')%u> "
# export PROMPT=%B%\(\?..\[%\?\]\ \)%b%n@%U%M%u\>\ 
# export PROMPT=%B%\(\?..\[%\?\]\ \)%b%n@%U$(hostname -f | awk -F $(hostname). '{print $2}')%u\>\  

#-- History Tweaks --#
HISTSIZE=10000
SAVEHIST=10000

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt APPEND_HISTORY

# for sharing history between zsh processes
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

#-- End of history tweaks --#

# For ctrl + arrow keys
bindkey ';5D' backward-word
bindkey ';5C' forward-word

# Use modern completion system
autoload -Uz compinit
compinit

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# alias to find the flag info
# modified from https://coderwall.com/p/gtgxww/intuitive-flags-information-of-nginx

if [ -f $HOME/.config/custom_aliases.sh ]; then
    source $HOME/.config/custom_aliases.sh
fi
