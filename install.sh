#!/usr/bin/env bash

URL=https://github.com/digitalocean/netbox/archive/v1.3.1.tar.gz
CURDIR=`pwd`

# Install pre-requisites
sudo apt-get install -y postgresql libpq-dev python-psycopg2

# Setup postgres
sudo -u postgres psql < ${CURDIR}/conf/postgres.conf

# Install app pre-requisites
sudo apt-get install -y python2.7 python-dev git python-pip libxml2-dev libxslt1-dev libffi-dev graphviz libpq-dev

# Download and install app
mkdir /tmp/netbox/
cd /tmp/netbox/
wget ${URL}
tar xzvf *.tar.gz -C /opt/
sudo ln -s /opt/netbox* /opt/netbox

# Install app requirements
cd /opt/netbox/
sudo pip install -r requirements.txt

# Setup configuration
cd netbox/netbox/
sudo cp configuration.example.py configuration.py
sudo sed -i "s/'USER': '',/'USER': 'netbox',/" configuration.py
PRIVATE_KEY=`python ../netbox/generate_secret_key.py`
sudo sed -i "s/SECRET_KEY = ''/SECRET_KEY = '${PRIVATE_KEY}'/" configuration.py

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
sudo cp ${CURDIR}/conf/nginx_netbox.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/netbox.conf /etc/nginx/sites-enabled/netbox.conf
sudo unlink /etc/nginx/sites-enabled/default
sudo service nginx restart

sudo cp ${CURDIR}/conf/gunicorn_config.py /opt/netbox/
sudo cp ${CURDIR}/conf/supervisor_netbox.conf /etc/supervisor/conf.d/netbox.conf
sudo service supervisor restart

echo "DONE"