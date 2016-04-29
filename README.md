Linux-Tweaks
============

Debian 8 is undoubtedly one of the leanest server distribution around this time (2016). It may not be the case after few years down the road, though. Until then, let's tweak it to some extend to make it more usable!

Tweaks on bash, zsh, vim, tmux, AWScli etc

## Install procedure

```bash
# as root

mkdir ~/scripts
curl -Sso ~/scripts/bootstrap_ltd8.sh https://raw.githubusercontent.com/pothi/linux-tweaks-debian-8/master/scripts/bootstrap_ltd8.sh
chmod +x ~/scripts/bootstrap_ltd8.sh

# go through the script to understand what it does. you are warned!
# vi ~/scripts/bootstrap_ltd8.sh

# run it and face the consequences
~/scripts/bootstrap_ltd8.sh

# (optional) get rid of all the evidences of making the changes
# rm ~/scripts/bootstrap_ltd8.sh

```
