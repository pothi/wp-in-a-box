# WP In A Box

Script/s to install WordPress in a linux box without much effort

## Install procedure

Rename `.envrc-sample` file as `.envrc` and insert as much information as possible

Download `bootstrap.sh` and execute it.

```bash
# as root

mkdir ~/scripts
curl -LSso ~/scripts/bootstrap.sh https://github.com/pothi/wp-in-a-box/raw/master/bootstrap.sh
chmod +x ~/scripts/bootstrap.sh

# go through the script to understand what it does. you are warned!
# vi ~/scripts/bootstrap.sh

# run it and face the consequences
~/scripts/bootstrap.sh

# (optional) get rid of all the evidences of making the changes
# rm ~/scripts/bootstrap.sh

```
