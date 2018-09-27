#!/bin/bash

# local installation

# clone and create  dirs
git clone https://github.com/chkgk/otree_manager.git /opt/otree_manager
mkdir -p /var/log/otree_manager

# setup venv
python3 -m venv /opt/otree_manager/venv

# activate venv and install requirements
source /opt/otree_manager/venv/bin/activate
pip install -r /opt/otree_manager/requirements.txt

# supervisor and nginx configs
cp /opt/otree_manager/conf/supervisor.conf /etc/supervisor/conf.d/otree_manager.conf
cp /opt/otree_manager/conf/nginx.conf /etc/nginx/conf.d/00_otree_manager.conf
rm /etc/nginx/sites-enabled/default

#restart services
service nginx restart
service supervisor restart
