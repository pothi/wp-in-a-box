#!/usr/bin/env bash

# https://wp-cli.org/#installing

wp_cli=/usr/local/bin/wp
#--- Install wp cli ---#
if [ ! -s "$wp_cli" ]; then
    printf '%-72s' "Downloading WP CLI..."
    wp_cli_url=https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    curl -LSsO $wp_cli_url
    if [ "$?" -ne "0" ]; then
        echo 'wp-cli: error downloading wp-cli.'
        exit 1
    fi
    chmod +x wp-cli.phar
    mv wp-cli.phar "$wp_cli"

    echo done.
fi

# wp cli bash completion
cd /etc/bash_completion.d/
if [ ! -s wp-completion.bash ]; then
    curl -LSsO https://github.com/wp-cli/wp-cli/raw/master/utils/wp-completion.bash
    if [ "$?" -ne "0" ]; then
        echo 'wp-cli: error downloading bash completion script.'
    fi
fi
cd - 1>/dev/null

#--- cron: auto-update wp-cli ---#
if ! grep -qF $wp_cli /var/spool/cron/crontabs/root 2>/dev/null
then
    ( crontab -l 2>/dev/null; echo "@daily $wp_cli cli update --yes 1>/dev/null" ) | crontab -
fi
