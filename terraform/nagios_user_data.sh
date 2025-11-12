#!/bin/bash
# Nagios Server User Data Script
# Initial setup for Nagios monitoring server

set -e

echo "Starting Nagios server initialization..."

# Update system packages
apt-get update
apt-get upgrade -y

# Install basic dependencies
apt-get install -y \
    build-essential \
    libssl-dev \
    libnet-snmp-perl \
    gettext \
    git \
    wget \
    curl \
    unzip \
    apache2 \
    apache2-utils \
    php \
    gdebi-core \
    net-tools \
    ntp \
    mailutils \
    s3cmd

# Set timezone
timedatectl set-timezone UTC

# Create nagios user and group
if ! id -u nagios > /dev/null 2>&1; then
    useradd -m -s /bin/bash nagios
fi

if ! getent group nagcmd > /dev/null 2>&1; then
    groupadd -f nagcmd
fi

# Add nagios and www-data users to nagcmd group
usermod -a -G nagcmd nagios
usermod -a -G nagcmd www-data

echo "Nagios server initialization completed"
