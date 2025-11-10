#!/bin/bash
# Post-deployment setup for Django application

# This script runs on the EC2 instance after initial deployment
# It handles additional configurations like SSL, logging directories, etc.

set -e

echo "Running post-deployment setup..."

# Create logging directories
sudo mkdir -p /var/log/gunicorn
sudo mkdir -p /var/log/django
sudo chown ubuntu:ubuntu /var/log/gunicorn
sudo chown ubuntu:ubuntu /var/log/django

# Create media and static directories
APP_DIR="/var/www/django-app"
mkdir -p $APP_DIR/media
mkdir -p $APP_DIR/staticfiles
chown -R ubuntu:ubuntu $APP_DIR/media
chown -R ubuntu:ubuntu $APP_DIR/staticfiles

# Create systemd log directory
sudo mkdir -p /var/log/django-app
sudo chown ubuntu:ubuntu /var/log/django-app

# Ensure database directory has correct permissions
chown -R ubuntu:ubuntu $APP_DIR/db.sqlite3

# Enable service auto-start on boot
sudo systemctl enable gunicorn
sudo systemctl enable nginx

echo "Post-deployment setup completed!"
