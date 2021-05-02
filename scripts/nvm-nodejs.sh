#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

[ -f ~/.envrc ] && . ~/.envrc

printf '%-72s' "Installing nodejs/npm..."
if [ ! -s ~/scripts/nvm-install-script.sh ]; then
    curl -L -o ~/scripts/nvm-install-script.sh https://raw.githubusercontent.com/nvm-sh/nvm/$nvm_version/install.sh
    # Creates an issue with GIT
    # bash ~/scripts/nvm-install-script.sh
    # export NVM_DIR="~/.nvm"
    # [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # this loads nvm
    # nvm install --lts
fi
echo done.

