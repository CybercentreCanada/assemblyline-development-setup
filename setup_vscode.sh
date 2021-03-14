#!/bin/sh -x

# Add Docker if missing
if ! command -v docker &> /dev/null
then
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
fi

# Download and install docker compose
if ! command -v docker-compose &> /dev/null
then
    sudo curl -L "https://github.com/docker/compose/releases/download/1.28.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo curl -L https://raw.githubusercontent.com/docker/compose/1.28.5/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
fi

# Setup dependencies
sudo apt install -y python3-venv python3.7 python3.7-dev python3.7-venv

# Clone git repos
git clone git@github.com:CybercentreCanada/assemblyline-base.git || git clone https://github.com/CybercentreCanada/assemblyline-base.git
git clone git@github.com:CybercentreCanada/assemblyline-core.git || git clone https://github.com/CybercentreCanada/assemblyline-core.git
git clone git@github.com:CybercentreCanada/assemblyline-service-server.git || git clone https://github.com/CybercentreCanada/assemblyline-service-server.git
git clone git@github.com:CybercentreCanada/assemblyline-ui.git || git clone https://github.com/CybercentreCanada/assemblyline-ui.git
git clone git@github.com:CybercentreCanada/assemblyline-service-client.git || git clone https://github.com/CybercentreCanada/assemblyline-service-client.git
git clone git@github.com:CybercentreCanada/assemblyline-v4-service.git || git clone https://github.com/CybercentreCanada/assemblyline-v4-service.git

# Setup venv
python3.7 -m venv venv
venv/bin/pip install -U pip
venv/bin/pip install -U pytest pytest-cov fakeredis[lua] retrying codecov pylint pep8 autopep8 ipython
venv/bin/pip install -e ./assemblyline-base
venv/bin/pip install -e ./assemblyline-core
venv/bin/pip install -e ./assemblyline-service-server
venv/bin/pip install -e ./assemblyline-service-client
venv/bin/pip install -e ./assemblyline-ui
venv/bin/pip install -e ./assemblyline-v4-service

# Remove temporary created file during install 
rm -rf assemblyline-base/assemblyline/common/frequency.c

# Self destruct!
rm -rf .git*
rm -rf setup_vscode.sh
rm -rf README.md
