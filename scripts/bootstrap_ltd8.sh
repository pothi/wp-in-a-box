#!/bin/bash

# Version: 1.1

# Changelog
# 2017-02-12 - version 1.1
#   awscli installation is simplified now
# 2017-02-12 - version 1.0
#   Tmux is not going to be installed and its config will be removed in a future version - just use screen going forward

# to be run as root, probably as a user-script just after a server is installed

# as root
# if [[ $USER != "root" ]]; then
# echo "This script must be run as root"
# exit 1
# fi

# TODO - change the default repo, if needed - mostly not needed on most hosts

# take a backup
mkdir -p /root/{backups,git,log,others,scripts,src,tmp,bin} &> /dev/null

LOG_FILE=/root/log/linux-tweaks.log
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

# take a backup
echo 'Taking an initial backup'
LT_DIRECTORY="/root/backups/etc-v1-linux-tweaks-before-$(date +%F)"
if [ ! -d "$LT_DIRECTORY" ]; then
	cp -a /etc $LT_DIRECTORY
fi


# install dependencies
echo 'Updating the server'
DEBIAN_FRONTEND=noninteractive apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get autoremove -y


# Install pre-requisites
echo 'Install prerequisites'
DEBIAN_FRONTEND=noninteractive apt-get install -y vim \
	unattended-upgrades apt-listchanges \
	dnsutils \
	git awscli \
	fail2ban ufw \
    mlocate \
	unzip zip \
	logwatch postfix mailutils \
    nodejs npm \
    redis-server \
    direnv duplicity

echo 'Taking another backup after installing packages'
LT_DIRECTORY="/root/backups/etc-v2-after-installing-standard-packages-$(date +%F)"
if [ ! -d "$LT_DIRECTORY" ]; then
	cp -a /etc $LT_DIRECTORY
fi

# setup timezone
timedatectl set-timezone UTC
if [ $? != 0 ]; then
	echo 'Error setting up timezone'
fi

# Unattended Upgrades
echo 'APT::Periodic::Update-Package-Lists "1";' > /etc/apt/apt.conf.d/20auto-upgrades
echo 'APT::Periodic::Unattended-Upgrade "1";' > /etc/apt/apt.conf.d/20auto-upgrades

# sed -i '/Unattended\-Upgrade::Mail/ s:^//::' /etc/apt/apt.conf.d/50unattended-upgrades
# sed -i '/Unattended-Upgrade::MailOnlyOnError/ s:^//::' /etc/apt/apt.conf.d/50unattended-upgrades
# if the following doesn't work, comment it and then uncomment the above two lines
sed -i '/\/\/Unattended-Upgrade::Mail\(OnlyOnError\)\?/ s:^//::' /etc/apt/apt.conf.d/50unattended-upgrades

# UFW
ufw default deny incoming

ufw allow 22
ufw allow 80
ufw allow 443

ufw --force enable
if [ $? != 0 ]; then
	echo 'Error setting up firewall'
fi

# get the source from Github
LTREPO=https://github.com/pothi/linux-tweaks-deb
echo 'Downloading Linux Tweaks from Github repo at '$LTREPO
rm -rf /root/ltweaks &> /dev/null
git clone $LTREPO /root/ltweaks

# Shell related configs
cp /root/ltweaks/custom_aliases.sh/etc/profile.d/
cp /root/ltweaks/custom_exports.sh/etc/profile.d/

# cp /root/ltweaks/zprofile /etc/zsh/zprofile
# cp /root/ltweaks/zshrc /etc/zsh/zshrc

# Vim related configs
cp /root/ltweaks/vimrc.local /etc/vim/
cp -a /root/ltweaks/vim/* /usr/share/vim/vim74/

# Misc files
cp /root/ltweaks/gitconfig /etc/gitconfig
# the following will be removed in a future version
# cp /root/ltweaks/tmux.conf /etc/tmux.conf

# Clean up
rm -rf /root/ltweaks/


# Common for all users
echo 'Setting up skel'
touch /etc/skel/.viminfo
# touch /etc/skel/.zshrc
# if ! grep '# Custom Code - PK' /etc/skel/.zshrc ; then
	# echo '# Custom Code - PK' > /etc/skel/.zshrc
	# echo 'HISTFILE=~/log/zsh_history' >> /etc/skel/.zshrc
	# echo 'export EDITOR=vim' >> /etc/skel/.zshrc
	# echo 'export VISUAL=vim' >> /etc/skel/.zshrc
# fi

touch /etc/skel/.vimrc
if ! grep '" Custom Code - PK' /etc/skel/.vimrc ; then
	echo '" Custom Code - PK' > /etc/skel/.vimrc
	echo "set viminfo+=n~/log/viminfo" >> /etc/skel/.vimrc
fi

# Copy common files to root
cp /etc/skel/.viminfo /root/
# cp /etc/skel/.zshrc /root/
cp /etc/skel/.vimrc /root/


# Change Shell
# echo 'Changing shell for root to ZSH'
# chsh --shell /usr/bin/zsh

# Setup some helper tools
echo 'Downloading ps_mem.py, mysqltuner and tuning-primer, etc'

PSMEMURL=http://www.pixelbeat.org/scripts/ps_mem.py
wget -q -O /root/ps_mem.py $PSMEMURL
chmod +x /root/ps_mem.py

TUNERURL=https://raw.github.com/major/MySQltuner-perl/master/mysqltuner.pl
wget -q -O /root/scripts/mysqltuner.pl $TUNERURL
chmod +x /root/scripts/mysqltuner.pl

PRIMERURL=https://launchpad.net/mysql-tuning-primer/trunk/1.6-r1/+download/tuning-primer.sh
wget -q -O /root/scripts/tuning-primer.sh $PRIMERURL
chmod +x /root/scripts/tuning-primer.sh

# Setup wp cli
echo 'Setting up WP CLI'
if [ ! -a /usr/local/bin/wp ]; then
	echo 'Setting up WP CLI'
	WPCLIURL=https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	curl --silent -O $WPCLIURL
	chmod +x wp-cli.phar
	mv wp-cli.phar /usr/local/bin/wp
fi

# take a backup, after doing everything
echo 'Taking a final backup'
LT_DIRECTORY="/root/backups/etc-linux-tweaks-after-$(date +%F)"
if [ ! -d "$LT_DIRECTORY" ]; then
	cp -a /etc $LT_DIRECTORY
fi

echo 'Installing MySQL / MariaDB Server'
# lets check if mariadb-server exists
SQL_SERVER=mariadb-server
if ! apt-cache show mariadb-server &> /dev/null ; then SQL_SERVER=mysql-server ; fi

DEBIAN_FRONTEND=noninteractive apt-get install ${SQL_SERVER} -y

echo 'Installing Nginx Server'
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx-extras-dbg
LT_DIRECTORY="/root/backups/etc-nginx-$(date +%F)"
if [ ! -d "$LT_DIRECTORY" ]; then
	cp -a /etc $LT_DIRECTORY
fi
git clone https://github.com/pothi/wordpress-nginx ~/git/wordpress-nginx
cp -a ~/git/wordpress-nginx/{conf.d, errors, globals, sites-available} /etc/nginx/

# logout and then login to see the changes
echo 'All done.'
echo 'You may logout and then log back in to see all the changes'
echo
