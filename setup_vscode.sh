#!/bin/sh -x

# Prepare sysctl for VSCode
sudo sysctl -w fs.inotify.max_user_watches=524288

# Add Docker if missing
if ! type docker > /dev/null
then
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
fi

# Setup sudoless docker 
sudo groupadd docker
sudo usermod -aG docker $USER

# Download and install docker compose
if ! type docker-compose > /dev/null
then
    sudo curl -L "https://github.com/docker/compose/releases/download/1.28.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo curl -L https://raw.githubusercontent.com/docker/compose/1.28.5/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
fi

# Setup dependencies
sudo apt-get update 
sudo apt-get install -yy python3-venv python3.7 python3.7-dev python3.7-venv libffi6 || sudo apt-get install -yy python3-venv python3.8 python3.8-dev python3.8-venv libffi7 
sudo apt-get install -yy libfuzzy2 libmagic1 libldap-2.4-2 libsasl2-2 build-essential libffi-dev libfuzzy-dev libldap2-dev libsasl2-dev libssl-dev

# Allow connections to github.com via SSH
ssh-keyscan github.com >> ~/.ssh/known_hosts

# Clone git repos
git clone git@github.com:CybercentreCanada/assemblyline-base.git || git clone https://github.com/CybercentreCanada/assemblyline-base.git
git clone git@github.com:CybercentreCanada/assemblyline-core.git || git clone https://github.com/CybercentreCanada/assemblyline-core.git
git clone git@github.com:CybercentreCanada/assemblyline-service-server.git || git clone https://github.com/CybercentreCanada/assemblyline-service-server.git
git clone git@github.com:CybercentreCanada/assemblyline-ui.git || git clone https://github.com/CybercentreCanada/assemblyline-ui.git
git clone git@github.com:CybercentreCanada/assemblyline-service-client.git || git clone https://github.com/CybercentreCanada/assemblyline-service-client.git
git clone git@github.com:CybercentreCanada/assemblyline-v4-service.git || git clone https://github.com/CybercentreCanada/assemblyline-v4-service.git

# Setup venv
python3.7 -m venv venv || python3.8 -m venv venv
venv/bin/pip install -U pip
venv/bin/pip install -U wheel
venv/bin/pip install -U pytest pytest-cov fakeredis[lua] retrying codecov flake8 pep8 autopep8 ipython
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
