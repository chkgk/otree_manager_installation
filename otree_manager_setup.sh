#!/bin/bash

# Combined installation script
main() {
    # Get hostname
    # we need this to correctly configure postfix, which is used for sending mail
    HOSTNAME="$(hostname)"

    # generate a random password for the PostgreSQL database.
    POSTGRES_PWD="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;)"

    # generate a root ssh key file if it does not exist
    if [ ! -f /root/.ssh/id_rsa.pub ]; then
        ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -P ""
    fi

    # install docker
    wget -nv -O - https://get.docker.com/ | sh

    # pre-configure postfix as an Internet site available at the current hostname
    debconf-set-selections <<< "postfix postfix/mailname string ${HOSTNAME}"
    debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

    # pre-configure dokku for an unattended installation, that is:
    # enable virtual host support
    # prevent web configuration tool from launching after installation
    # set hostname
    # skip ssh key file verification during installation
    # manually set the root ssh key file.
    debconf-set-selections <<< "dokku dokku/vhost_enable boolean true"
    debconf-set-selections <<< "dokku dokku/web_config boolean false"
    debconf-set-selections <<< "dokku dokku/hostname string ${HOSTNAME}"
    debconf-set-selections <<< "dokku dokku/skip_key_file boolean true"
    debconf-set-selections <<< "dokku dokku/key_file string /root/.ssh/id_rsa.pub"
    debconf-set-selections <<< "dokku dokku/nginx_enable boolean true"

    # add dokku repository to apt package manager, then trigger an update
    wget -nv -O - https://packagecloud.io/dokku/dokku/gpgkey | apt-key add -
    OS_ID="$(lsb_release -cs 2> /dev/null || echo "trusty")"
    echo "trusty utopic vivid wily xenial yakkety zesty artful bionic" | grep -q "$OS_ID" || OS_ID="trusty"
    echo "deb https://packagecloud.io/dokku/dokku/ubuntu/ ${OS_ID} main" | tee /etc/apt/sources.list.d/dokku.list
    apt update 

    # install dependencies
    apt install -y apt-transport-https postfix redis-server postgresql python3 python3-pip python3-dev python3-venv nginx supervisor dokku

    # install dokku plugins
    # dokku-acl provides user access management
    # postgres provides PostgreSQL database containers
    # redis provides redis database containers
    dokku plugin:install-dependencies --core
    dokku plugin:install https://github.com/dokku-community/dokku-acl.git acl
    dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres
    dokku plugin:install https://github.com/dokku/dokku-redis.git redis

    # create postgres database
    # configure a user account for otree_manager and set the necessary permissions
    sudo -u postgres psql -c "CREATE DATABASE otree_manager;"
    sudo -u postgres psql -c "CREATE USER otree_manager_user WITH PASSWORD '${POSTGRES_PWD}';"
    sudo -u postgres psql -c "ALTER ROLE otree_manager_user SET client_encoding TO 'utf8';"
    sudo -u postgres psql -c "ALTER ROLE otree_manager_user SET default_transaction_isolation TO 'read committed';"
    sudo -u postgres psql -c "ALTER ROLE otree_manager_user SET timezone TO 'UTC';"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE otree_manager TO otree_manager_user;"

    # config smtp server for sending emails
    # it is configured to be only able to send messages from local connections
    sed -i '/inet_interfaces = all/c\inet_interfaces = localhost' /etc/postfix/main.cf
    postfix reload

    # install oTree Manager
    # clone the current release of oTree manager from GitHub
    git clone https://github.com/chkgk/otree_manager.git /opt/otree_manager
    mkdir -p /var/log/otree_manager

    # setup a Python 3 virtual environment for oTree Manager
    # this allows us to separate oTree Managers' environment from system Python packages
    python3 -m venv /opt/otree_manager/venv

    # activate the virtual environment and install required python packages
    source /opt/otree_manager/venv/bin/activate
    export POSTGRES_PWD="${POSTGRES_PWD}"
    pip install --upgrade pip
    pip install wheel setuptools
    pip install -r /opt/otree_manager/requirements.txt

    # update config files
    # oTree Manager is started on boot by supervisor. Here we write the randomly generated database password to
    # supervisor's configuration file so it can be provided as an environmental variable to oTree Manager
    sed -i "/    POSTGRES_PWD=\"passwordnotset\"/c\    POSTGRES_PWD=\"${POSTGRES_PWD}\"" /opt/otree_manager/conf/supervisor.conf

    # copy supervisor and nginx configs into place
    # nginx serves as a reverse proxy to enable transport layer security to be used with http (https!)
    # supervisor is responsible for keeping oTree Manager alive, start it on boot etc.
    cp /opt/otree_manager/conf/supervisor.conf /etc/supervisor/conf.d/otree_manager.conf
    cp /opt/otree_manager/conf/nginx.conf /etc/nginx/conf.d/00_otree_manager.conf
    rm /etc/nginx/sites-enabled/default

    # final steps
    # first, collect static files from oTree Manager, then apply migrations to make sure the database is initialized
    python /opt/otree_manager/otree_manager/manage.py collectstatic
    python /opt/otree_manager/otree_manager/manage.py migrate

    # setup root user
    # ask user for a superuser name and password to be used as the initial super-user account of oTree Manager.
    echo "You will now create the first super-user account for oTree Manager."
    python /opt/otree_manager/otree_manager/manage.py createsuperuser

}

main "$@"
# after installation has completed, reload nginx and supervisor configuration files.
service nginx reload
service supervisor reload