#!/bin/bash

#--- Install pre-requisites ---#
# landscape-common update-notifier-common \
echo 'Install prerequisites'
DEBIAN_FRONTEND=noninteractive apt-get install -y vim \
    apt-file \
    bash-completion \
	dnsutils \
	logwatch mailutils \
    mlocate \
    postfix \
	unattended-upgrades apt-listchanges \
	zip unzip  \
	awscli \
    nodejs npm \
    redis-server \
    direnv duplicity \
    pwgen \
    letsencrypt \
    apache2-utils

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
if ! grep 'direnv' /root/.bashrc &> /dev/null ; then
    echo 'eval "$(direnv hook bash)"' >> /root/.bashrc &> /dev/null
fi

if [ -f /root/.envrc ]; then
    chmod 600 /root/.envrc
    source /root/.envrc
    direnv allow &> /dev/null
fi


#--- Setup some helper tools ---#
if [ ! -s /root/ps_mem.py ]; then
    echo 'Downloading ps_mem.py'
    PSMEMURL=http://www.pixelbeat.org/scripts/ps_mem.py
    wget -q -O /root/ps_mem.py $PSMEMURL
    chmod +x /root/ps_mem.py
fi

if [ ! -s /root/scripts/mysqltuner.pl ]; then
    echo 'Downloading mysqltuner'
    TUNERURL=https://raw.github.com/major/MySQltuner-perl/master/mysqltuner.pl
    wget -q -O /root/scripts/mysqltuner.pl $TUNERURL
    chmod +x /root/scripts/mysqltuner.pl
fi

if [ ! -s /root/scripts/tuning-primer.sh ]; then
    echo 'Downloading tuning-primer'
    PRIMERURL=https://launchpad.net/mysql-tuning-primer/trunk/1.6-r1/+download/tuning-primer.sh
    wget -q -O /root/scripts/tuning-primer.sh $PRIMERURL
    chmod +x /root/scripts/tuning-primer.sh
fi


#--- Setup wp cli ---#
if [ ! -s /usr/local/bin/wp ]; then
	echo 'Setting up WP CLI'
	WPCLIURL=https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	curl --silent -O $WPCLIURL
	chmod +x wp-cli.phar
	mv wp-cli.phar /usr/local/bin/wp
fi

