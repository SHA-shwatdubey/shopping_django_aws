#!/bin/bash
set -e

# Update system packages
apt-get update
apt-get upgrade -y

# Install basic utilities
apt-get install -y curl wget git unzip htop

# Log completion
echo "User data script completed on $(date)" >> /var/log/user-data.log
