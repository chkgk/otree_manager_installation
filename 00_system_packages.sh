#!/bin/bash
# installation script for oTree Manager

HOSTNAME="$(hostname)"

# pre-configure packages
debconf-set-selections <<< "postfix postfix/mailname string ${HOSTNAME}"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

# install system packages
apt install -y apt-transport-https postfix redis-server postgresql python3 python3-pip python3-dev python3-venv nginx supervisor git

# config smtp server send only, accept local connections
sed -i '/inet_interfaces = all/c\inet_interfaces = localhost' /etc/postfix/main.cf
postfix reload


