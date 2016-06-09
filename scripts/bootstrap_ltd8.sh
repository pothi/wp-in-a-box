#!/bin/bash

# to be run as root, probably as a user-script just after a server is installed

# as root
# if [[ $USER != "root" ]]; then
# echo "This script must be run as root"
# exit 1
# fi

# TODO - change the default repo, if needed - mostly not needed on most hosts

# take a backup
mkdir -p /root/{backups,log,scripts,tmp,git,src,others} &> /dev/null

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
DEBIAN_FRONTEND=noninteractive apt-get install -y zsh \
	vim \
	tmux \
	unattended-upgrades apt-listchanges \
	dnsutils \
	git \
	python-pip \
	fail2ban \
	unzip zip \
	logwatch postfix mailutils \
	ufw

echo 'Install AWS CLI tools'
pip install awscli

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
LTREPO=https://github.com/pothi/linux-tweaks-debian-8.git
echo 'Downloading Linux Tweaks from Github repo at '$LTREPO
rm -rf /root/ltd8 &> /dev/null
git clone --recursive $LTREPO /root/ltd8

# Shell related configs
cp /root/ltd8/tiny_* /etc/profile.d/

cp /root/ltd8/zprofile /etc/zsh/zprofile
cp /root/ltd8/zshrc /etc/zsh/zshrc

# Vim related configs
cp /root/ltd8/vimrc.local /etc/vim/vimrc.local
cp -a /root/ltd8/vim/* /usr/share/vim/vim74/
git clone https://github.com/VundleVim/Vundle.vim.git /usr/share/vim/vim74/bundle/Vundle.vim
git clone https://github.com/mattn/emmet-vim.git /usr/share/vim/vim74/bundle/emmet-vim

# Misc files
cp /root/ltd8/tmux.conf /etc/tmux.conf
cp /root/ltd8/gitconfig /etc/gitconfig

# Clean up
rm -rf /root/ltd8/


# Common for all users
echo 'Setting up skel'
touch /etc/skel/.viminfo
touch /etc/skel/.zshrc
if ! grep '# Custom Code - PK' /etc/skel/.zshrc ; then
	echo '# Custom Code - PK' >> /etc/skel/.zshrc
	echo 'HISTFILE=~/log/zsh_history' >> /etc/skel/.zshrc
	echo 'export EDITOR=vim' >> /etc/skel/.zshrc
	echo 'export VISUAL=vim' >> /etc/skel/.zshrc
fi

touch /etc/skel/.vimrc
if ! grep '" Custom Code - PK' /etc/skel/.vimrc ; then
	# attempt to create a log directory, if not exists
	echo '" Custom Code - PK' >> /etc/skel/.vimrc
	# Change the path to viminfo; from ~/.viminfo to ~/log/viminfo
	echo "set viminfo+=n~/log/viminfo" >> /etc/skel/.vimrc
fi

# Copy common files to root
cp /etc/skel/.viminfo /root/
cp /etc/skel/.zshrc /root/
cp /etc/skel/.vimrc /root/


# Change Shell
echo 'Changing shell for root to ZSH'
chsh --shell /usr/bin/zsh


#### Update Pathogen (optional)
if [ ! -a "/usr/share/vim/vim74/autoload/pathogen.vim" ]; then
	echo 'Updating Pathogen (for VIM)'
	PATHOGENURL=https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim

	echo 'Updating Pathogen (for VIM)'
	wget -q -O /root/pathogen.vim $PATHOGENURL

	# if the file exists AND has a size greater than zero.
	# zero means the download failed
	if [ -s /root/pathogen.vim ]; then
		mv /root/pathogen.vim /usr/share/vim/vim74/autoload/pathogen.vim
	else
		rm /root/pathogen.vim
		echo 'Failed to download pathogen' >> $LOG_FILE
	fi
fi

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

