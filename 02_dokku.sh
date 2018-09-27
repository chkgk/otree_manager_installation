#!/bin/bash
# install dokku, try unattended install

# generate a key file if it does not exist

if [ ! -f /root/.ssh/id_rsa.pub ]; then
	ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -P ""
fi
# adapted from dokku manual

# install docker
wget -nv -O - https://get.docker.com/ | sh

# pre-configure dokku
echo "dokku dokku/vhost_enable boolean true" | debconf-set-selections
echo "dokku dokku/web_config boolean false" | debconf-set-selections
echo "dokku dokku/hostname string $(hostname)" | debconf-set-selections
echo "dokku dokku/skip_key_file boolean true" | debconf-set-selections
echo "dokku dokku/key_file string /root/.ssh/id_rsa.pub" | debconf-set-selections

# install dokku
wget -nv -O - https://packagecloud.io/gpg.key | apt-key add -
OS_ID="$(lsb_release -cs 2> /dev/null || echo "trusty")"
echo "trusty utopic vivid wily xenial yakkety zesty artful bionic" | grep -q "$OS_ID" || OS_ID="trusty"
echo "deb https://packagecloud.io/dokku/dokku/ubuntu/ ${OS_ID} main" | tee /etc/apt/sources.list.d/dokku.list
apt update 
apt install -y dokku
dokku plugin:install-dependencies --core

# install dokku plugins
dokku plugin:install https://github.com/dokku-community/dokku-acl.git acl
dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres
dokku plugin:install https://github.com/dokku/dokku-redis.git redis