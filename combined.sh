#!/bin/bash

# Combined installation script

# get hostname
HOSTNAME="$(hostname)"

# random password for postgres. 
POSTGRES_PWD="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;)"

# generate a key file if it does not exist
if [ ! -f /root/.ssh/id_rsa.pub ]; then
	ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -P ""
fi

# install docker
wget -nv -O - https://get.docker.com/ | sh

# pre-configure postfix
debconf-set-selections <<< "postfix postfix/mailname string ${HOSTNAME}"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

# pre-configure dokku
debconf-set-selections <<< "dokku dokku/vhost_enable boolean true"
debconf-set-selections <<< "dokku dokku/web_config boolean false"
debconf-set-selections <<< "dokku dokku/hostname string ${HOSTNAME}"
debconf-set-selections <<< "dokku dokku/skip_key_file boolean true"
debconf-set-selections <<< "dokku dokku/key_file string /root/.ssh/id_rsa.pub"

# add repositories
wget -nv -O - https://packagecloud.io/gpg.key | apt-key add -
OS_ID="$(lsb_release -cs 2> /dev/null || echo "trusty")"
echo "trusty utopic vivid wily xenial yakkety zesty artful bionic" | grep -q "$OS_ID" || OS_ID="trusty"
echo "deb https://packagecloud.io/dokku/dokku/ubuntu/ ${OS_ID} main" | tee /etc/apt/sources.list.d/dokku.list
apt update 

# install system packages
apt install -y apt-transport-https postfix redis-server postgresql python3 python3-pip python3-dev python3-venv nginx supervisor git dokku

# install dokku plugins
dokku plugin:install-dependencies --core
dokku plugin:install https://github.com/dokku-community/dokku-acl.git acl
dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres
dokku plugin:install https://github.com/dokku/dokku-redis.git redis

# create postgres database
sudo -u postgres psql -c "CREATE DATABASE otree_manager;"
sudo -u postgres psql -c "CREATE USER otree_manager_user WITH PASSWORD '${POSTGRES_PWD}';"
sudo -u postgres psql -c "ALTER ROLE otree_manager_user SET client_encoding TO 'utf8';"
sudo -u postgres psql -c "ALTER ROLE otree_manager_user SET default_transaction_isolation TO 'read committed';"
sudo -u postgres psql -c "ALTER ROLE otree_manager_user SET timezone TO 'UTC';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE otree_manager TO otree_manager_user;"

# config smtp server send only, accept local connections
sed -i '/inet_interfaces = all/c\inet_interfaces = localhost' /etc/postfix/main.cf
postfix reload

# clone and create  dirs
git clone https://github.com/chkgk/otree_manager.git /opt/otree_manager
mkdir -p /var/log/otree_manager

# setup venv
python3 -m venv /opt/otree_manager/venv

# activate venv and install requirements
source /opt/otree_manager/venv/bin/activate
pip install --upgrade pip
pip install wheel setuptools
pip install -r /opt/otree_manager/requirements.txt

# update config files
sed -i "/    POSTGRES_PWD=\"passwordnotset\"/c\    POSTGRES_PWD=\"${POSTGRES_PWD}\"" /opt/otree_manager/conf/supervisor.conf

# copy supervisor and nginx configs into place
cp /opt/otree_manager/conf/supervisor.conf /etc/supervisor/conf.d/otree_manager.conf
cp /opt/otree_manager/conf/nginx.conf /etc/nginx/conf.d/00_otree_manager.conf
rm /etc/nginx/sites-enabled/default

# final steps
python /opt/otree_manager/otree_manager/manage.py collectstatic
python /opt/otree_manager/otree_manager/manage.py migrate

# setup root user
echo "You will now create the first super-user account for oTree Manager."
python /opt/otree_manager/otree_manager/manage.py createsuperuser

# restart services
service nginx restart
service supervisor restart