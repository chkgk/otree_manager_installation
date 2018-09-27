#!/bin/bash

# local installation

# clome and create  dirs
#git clone https://github.com/chkgk/otree_manager.git /opt/otree_manager
mkdir -p /var/log/otree_manager

# setup venv
python3 -m venv /opt/otree_manager/venv

# activate venv and install requirements
source /opt/otree_manager/venv/bin/activate
pip install -r /opt/otree_manager/requirements.txt
