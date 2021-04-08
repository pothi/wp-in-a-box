#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# TODO

# optional parameters
# EMAIL
# SMTP_USERNAME=
# SMTP_PASSWORD=
# SMTP_HOST=
# SMTP_PORT=

mta=postfix

echo 'Installing / setting up MTA...'

# dependencies
# https://serverfault.com/a/325975/102173
apt-get install -qq libsasl2-modules &> /dev/null

apt-get install -qq $mta &> /dev/null

# setup mta to use only ipv4 to send emails
#- why:
#- https://support.google.com/mail/?p=IPv6AuthError
#- every host doesn't support IPv6
#- every host doesn't support setting up reverse DNS
#- Linode: when swapping IPs, it only swaps IPv4, not IPv6 :(
postconf -e 'inet_protocols = ipv4'

# encrypt outgoing emails
# ref: http://blog.snapdragon.cc/2013/07/07/setting-postfix-to-encrypt-all-traffic-when-talking-to-other-mailservers/
postconf -e 'smtp_tls_security_level = encrypt'
postconf -e 'smtp_tls_wrappermode = yes'
postconf -e 'smtpd_tls_security_level = may'
postconf -e 'smtp_tls_loglevel = 1'
postconf -e 'smtpd_tls_loglevel = 1'
# ref: https://serverfault.com/q/858311/102173
postconf -e 'smtp_tls_CApath = /etc/ssl/certs'
postconf -e 'smtpd_tls_CApath = /etc/ssl/certs'

# only applicable to Debian and Ubuntu
postconf -e 'smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt'

postconf -e 'smtp_use_tls = yes'
postconf -e 'smtp_tls_note_starttls_offer = yes'

# limit outgoing rate
postconf -e 'smtp_destination_concurrency_limit = 2'
postconf -e 'smtp_destination_rate_delay = 60s'

# look for spam
postconf -e 'header_checks = regexp:/etc/postfix/header_checks'
postconf -e 'smtp_header_checks = regexp:/etc/postfix/header_checks'

/usr/sbin/postfix check && systemctl restart $mta

check_result $? "Warning: Something went wrong while restarting MTA ($mta). Continuing..."

echo "... done setting up MTA (${mta})!"
