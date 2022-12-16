#!/usr/bin/env bash

# https://wp-cli.org/#installing

# set -x

# to capture non-zero exit code in the pipeline
set -o pipefail

# check root user
# https://stackoverflow.com/a/52586842/1004587
# also see https://stackoverflow.com/q/3522341/1004587
is_user_root () { [ "${EUID:-$(id -u)}" -eq 0 ]; }
if is_user_root; then
    BinDir=/usr/local/bin
    bash_completion_dir=/etc/bash_completion.d
else
    BinDir=~/.local/bin
    # https://serverfault.com/a/968369/102173
    bash_completion_dir=${BASH_COMPLETION_USER_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion}/completions
    # attempt to create BinDir and bash_completion_dir
    [ -d $BinDir ] || mkdir -p $BinDir
    if [ "$?" -ne "0" ]; then
        echo "BinDir is not found at $BinDir. This script can't create it, either!"
        echo 'You may create it manually and re-run this script.'
        exit 1
    fi
    [ -d $bash_completion_dir ] || mkdir -p $bash_completion_dir
    if [ "$?" -ne "0" ]; then
        echo "bash_completion_dir is not found at $bash_completion_dir. This script can't create it, either!"
        echo 'You may create it manually and re-run this script.'
        exit 1
    fi
fi

export PATH=~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

wp_cli=${BinDir}/wp
#--- Install wp cli ---#
if [ ! -s "$wp_cli" ]; then
    printf '%-72s' "Downloading WP CLI..."
    wp_cli_url=https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    curl -LSs -o "$wp_cli" $wp_cli_url
    if [ "$?" -ne "0" ]; then
        echo 'wp-cli: error downloading wp-cli.'
        exit 1
    fi
    chmod +x "$wp_cli"

    echo done.
fi

# wp cli bash completion
if [ ! -s $bash_completion_dir/wp-completion.bash ]; then
    curl -LSs -o "${bash_completion_dir}/wp-completion.bash" https://github.com/wp-cli/wp-cli/raw/main/utils/wp-completion.bash
    if [ "$?" -ne "0" ]; then
        echo 'wp-cli: error downloading bash completion script.'
    fi
fi

#--- cron: auto-update wp-cli ---#
if ! grep -qF $wp_cli "/var/spool/cron/crontabs/$USER" 2>/dev/null
then
    ( crontab -l 2>/dev/null; echo "@daily $wp_cli cli update --yes &> /dev/null" ) | crontab -
fi
