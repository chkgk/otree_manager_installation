#!/bin/bash

# random passwor for db. user should never need this.
POSTGRES_PWD="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;)"

sudo -u postgres psql -c "CREATE DATABASE otree_manager;"
sudo -u postgres psql -c "CREATE USER otree_manager_user WITH PASSWORD '${POSTGRES_PWD}';"
sudo -u postgres psql -c "ALTER ROLE otree_manager_user SET client_encoding TO 'utf8';"
sudo -u postgres psql -c "ALTER ROLE otree_manager_user SET default_transaction_isolation TO 'read committed';"
sudo -u postgres psql -c "ALTER ROLE otree_manager_user SET timezone TO 'UTC';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE otree_manager TO otree_manager_user;"

