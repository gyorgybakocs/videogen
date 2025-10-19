#!/bin/bash
#
# server_init.sh
#
# This script installs Docker, kubectl, Minikube, and the AWS CLI v2
# on a fresh Debian-based Linux system (e.g., Ubuntu).
# It must be run as root or with sudo privileges.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "========================================================================"
echo "=> 1. Updating system and installing prerequisite packages..."
echo "========================================================================"
apt-get update
apt-get install -y ca-certificates curl gnupg unzip

echo "========================================================================"
echo "=> 2. Installing Docker..."
echo "========================================================================"
# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Set up the Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
echo "=> Docker installed successfully!"

echo "========================================================================"
echo "=> 2. Installing HuggingFace..."
echo "========================================================================"
apt-get update
apt-get install -y python3-pip
python3 -m pip install -U huggingface_hub
hash -r

echo "========================================================================"
echo "=> INSTALLATION COMPLETE! The system is ready to run 'make mk-build'."
echo "========================================================================"
