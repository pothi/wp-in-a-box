#!/bin/bash

# TODO

# optional parameters
# EMAIL
# SMTP_USERNAME=
# SMTP_PASSWORD=
# SMTP_HOST=
# SMTP_PORT=

DEBIAN_FRONTEND=noninteractive apt install -y postfix

# setup mta to use only ipv4 to send emails
#- why:
#- https://support.google.com/mail/?p=IPv6AuthError
#- every host doesn't support IPv6
#- every host doesn't support setting up reverse DNS
#- Linode: when swapping IPs, it only swaps IPv4, not IPv6 :(
postconf -e 'inet_protocols = ipv4'

postfix check && systemctl restart postfix
