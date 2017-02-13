#!/bin/bash

#--- Install pre-requisites ---#
echo 'Install prerequisites'
DEBIAN_FRONTEND=noninteractive apt-get install -y vim \
	unattended-upgrades apt-listchanges \
	dnsutils \
	git awscli \
    mlocate \
	unzip zip \
	logwatch mailutils \
    nodejs npm \
    redis-server \
    direnv duplicity

#--- setup timezone ---#
timedatectl set-timezone UTC
if [ $? != 0 ]; then
	echo 'Error setting up timezone'
fi

#--- Unattended Upgrades ---#
echo 'APT::Periodic::Update-Package-Lists "1";' > /etc/apt/apt.conf.d/20auto-upgrades
echo 'APT::Periodic::Unattended-Upgrade "1";' > /etc/apt/apt.conf.d/20auto-upgrades

# sed -i '/Unattended\-Upgrade::Mail/ s:^//::' /etc/apt/apt.conf.d/50unattended-upgrades
# sed -i '/Unattended-Upgrade::MailOnlyOnError/ s:^//::' /etc/apt/apt.conf.d/50unattended-upgrades
# if the following doesn't work, comment it and then uncomment the above two lines
sed -i '/\/\/Unattended-Upgrade::Mail\(OnlyOnError\)\?/ s:^//::' /etc/apt/apt.conf.d/50unattended-upgrades

#--- Setup direnv ---#
if ! grep 'direnv' /root/.bashrc ; then
    echo 'eval "$(direnv hook bash)"' >> /root/.bashrc
fi

#--- Common for all users ---#
echo 'Setting up skel'

touch /etc/skel/.bashrc &> /dev/null
if ! grep 'direnv' /etc/skel/.bashrc &> /dev/null ; then
    echo 'eval "$(direnv hook bash)"' >> /etc/skel/.bashrc
fi

mkdir /etc/skel/.vim &> /dev/null
touch /etc/skel/.vimrc &> /dev/null
if ! grep '" Custom Code - PK' /etc/skel/.vimrc &> /dev/null ; then
	echo '" Custom Code - PK' > /etc/skel/.vimrc
	echo "set viminfo+=n~/.vim/viminfo" >> /etc/skel/.vimrc
fi

# cp /etc/skel/.zshrc /root/
cp /etc/skel/.vimrc /root/

# touch /etc/skel/.zshrc
# if ! grep '# Custom Code - PK' /etc/skel/.zshrc ; then
	# echo '# Custom Code - PK' > /etc/skel/.zshrc
	# echo 'HISTFILE=~/log/zsh_history' >> /etc/skel/.zshrc
	# echo 'export EDITOR=vim' >> /etc/skel/.zshrc
	# echo 'export VISUAL=vim' >> /etc/skel/.zshrc
# fi


### Change Shell
# echo 'Changing shell for root to ZSH'
# chsh --shell /usr/bin/zsh

#--- Setup some helper tools ---#
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


#--- Setup wp cli ---#
if [ ! -a /usr/local/bin/wp ]; then
	echo 'Setting up WP CLI'
	WPCLIURL=https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	curl --silent -O $WPCLIURL
	chmod +x wp-cli.phar
	mv wp-cli.phar /usr/local/bin/wp
fi

