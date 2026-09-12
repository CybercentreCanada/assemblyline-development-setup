#!/bin/bash

# Setup script for developing in Assemblyline using DevContainers
set -e

# Warmup sudo password
sudo true

# Install VSCode (preferred IDE by the Assemblyline team)
sudo sysctl -w fs.inotify.max_user_watches=524288
sudo whereis code || sudo snap install code --classic

# Add Docker if missing
if ! type docker &> /dev/null
then
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
fi

# Setup sudoless docker
sudo groupadd docker 2>/dev/null || echo "Docker group already exists"
sudo usermod -aG docker $USER

# Create Docker daemon configuration for insecure registry
sudo mkdir -p /etc/docker/
echo "{ \"insecure-registries\":[\"$(ip addr show docker0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/'):32000\"] }" | sudo tee /etc/docker/daemon.json

# Allow connections to github.com via SSH
mkdir -p ~/.ssh
touch ~/.ssh/known_hosts
ssh-keyscan github.com >> ~/.ssh/known_hosts

# As part of the initial setup, clone active repositories
for repo in -base -core -rust -ui -ui-frontend _client -service-client -v4-service
do
    git clone git@github.com:CybercentreCanada/assemblyline$repo.git || git clone https://github.com/CybercentreCanada/assemblyline$repo.git || echo "assemblyline$repo repo already exists"
done
