# Set default key bindings to VIM, if you prefer!
# bindkey -v

# Set default theme - walters
autoload -U promptinit
promptinit
prompt walters
setopt PROMPT_SUBST
export PROMPT="%B%(?..[%?] )%b%n@%U$(hostname -f | awk -F . '{print $2"."$3}')%u> "
# PROMPT=%B%\(\?..\[%\?\]\ \)%b%n@%U%M%u\>\ 
# PROMPT=%B%\(\?..\[%\?\]\ \)%b%n@%U$(hostname -f | awk -F $(hostname). '{print $2}')%u\>\  

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

# Aliases for `ls`

alias ls='ls --color=auto --group-directories-first --classify'
alias l='ls --color=auto --group-directories-first --classify'
# use the following if --color=auto did not work
# alias l='ls --color=always --group-directories-first --classify'
# use --color=never, to turn off colors

alias la='l --almost-all'
alias ld='l -ldh'
alias ll='l -lh' 
alias lh='l -lh'

alias lal='l -lh --almost-all'
alias lla='lal'
alias llh='ll'

# alias wl='wc -l'
alias fm='free -m'
alias c='cd'
# alias ping='ping -c 1'

# Sed
alias sedf='/bin/sed --follow-symlinks'

### Curl aliases ###
### Ref - http://curl.haxx.se/docs/manpage.html
# alias curli='curl -I'
# alias curlih='curl -I -H "Accept-Encoding:gzip,deflate"'
alias curld='curl -H "Accept-Encoding:gzip,deflate" -s -D- -o /dev/null'

# Explanation for the above
# curli='curl --head' # strange character to replace --head
# curlih='curl -I --header "Accept-Encoding:gzip,deflate"'
# curld='curl -H "Accept-Encoding:gzip,deflate" --silent --dump-header - --output /dev/null'

# Dig aliases
alias digs='dig +short'
alias digc='dig +short CNAME'
alias digns='dig +short NS'
alias digmx='dig +short MX'

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
alias ngx_flags='nginx -V 2>&1 | /bin/sed "s: --:\n\t&:g"'
