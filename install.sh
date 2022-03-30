#!/usr/bin/env bash

VERSION=1.7.0
URL=https://github.com/digitalocean/netbox/archive/v${VERSION}.tar.gz
CURDIR=`pwd`

# Install pre-requisites
sudo apt-get install -y postgresql libpq-dev python3-psycopg2

# Setup postgres
sudo -u postgres psql < ${CURDIR}/conf/postgres.conf

# Install app pre-requisites
sudo apt-get install -y python2.7 python-dev python3-pip libxml2-dev libxslt1-dev libffi-dev graphviz libpq-dev libssl-dev
sudo pip install --upgrade pip

# Download and install app
mkdir /tmp/netbox/
cd /tmp/netbox/
wget ${URL}
tar xzvf v${VERSION}.tar.gz -C /opt/
sudo ln -s /opt/netbox-${VERSION} /opt/netbox

# Install app requirements
cd /opt/netbox/
sudo pip install -r requirements.txt

# Setup configuration
cd netbox/netbox/
sudo cp configuration.example.py configuration.py
sudo sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \['*'\]/" /opt/netbox/netbox/netbox/configuration.py
sudo sed -i "s/'USER': '',/'USER': 'netbox',/" /opt/netbox/netbox/netbox/configuration.py
sudo sed -i "s/'PASSWORD': '',           # PostgreSQL password/'PASSWORD': 'somethingsomethingsomethingdarkside',/" /opt/netbox/netbox/netbox/configuration.py
PRIVATE_KEY='aslknfdslakfn3q43qknSKNDKNalisjf23jnlknd2kdn2dsknasdKN'
sudo sed -i "s/SECRET_KEY = ''/SECRET_KEY = '${PRIVATE_KEY}'/" /opt/netbox/netbox/netbox/configuration.py

# Run database migrations
cd /opt/netbox/netbox/
sudo python manage.py migrate

# Create super user
sudo python manage.py createsuperuser

# Collect static files
sudo python manage.py collectstatic

# Install webservers
sudo apt-get install -y gunicorn supervisor nginx

# Configure webservers
sudo cp ${CURDIR}/conf/nginx_netbox.conf /etc/nginx/sites-available/netbox.conf
sudo ln -s /etc/nginx/sites-available/netbox.conf /etc/nginx/sites-enabled/netbox.conf
sudo unlink /etc/nginx/sites-enabled/default
sudo service nginx restart

sudo cp ${CURDIR}/conf/gunicorn_config.py /opt/netbox/
sudo cp ${CURDIR}/conf/supervisor_netbox.conf /etc/supervisor/conf.d/netbox.conf
sudo service supervisor restart

echo "DONE"
