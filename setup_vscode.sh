#!/bin/bash

usage() { echo "Usage: $0 [-c] [-h] [-s] [-k]" 1>&2; exit 1; }

# Get command line options
while getopts "cskh" arg; do
  case $arg in
    c) # Install VSCode
      code="yes"
      ;;
    s) # Setup services as well
      services="yes"
      ;;
    k) # Setup for Kubernetes (alpha)
      kubernetes="yes"
      ;;
    h) # Show usage
      usage
      ;;
  esac
done

# Warmup sudo password
sudo true

# Create Assemblyline folders
sudo mkdir -p /etc/assemblyline
sudo mkdir -p /var/cache/assemblyline
sudo mkdir -p /var/lib/assemblyline
sudo mkdir -p /var/log/assemblyline

sudo chown $USER /etc/assemblyline
sudo chown $USER /var/cache/assemblyline
sudo chown $USER /var/lib/assemblyline
sudo chown $USER /var/log/assemblyline

# Create default classification.yml
echo "
enforce: false
dynamic_groups: false
" > /etc/assemblyline/classification.yml

# Create default config.yml
echo "
auth:
  internal:
    enabled: true

core:
  alerter:
    delay: 0
  scaler:
    service_defaults:
      min_instances: 0
  metrics:
    apm_server:
      server_url: http://localhost:8200/
    elasticsearch:
      hosts: [http://elastic:devpass@localhost]

datastore:
  ilm:
    enabled: false
    indexes:
      alert:
        unit: m
      error:
        unit: m
      file:
        unit: m
      result:
        unit: m
      submission:
        unit: m

filestore:
  cache:
    - file:///var/cache/assemblyline/

logging:
  log_level: INFO
  log_as_json: false

services:
  preferred_update_channel: dev

system:
  type: development

ui:
  audit: false
  debug: false
  enforce_quota: false
  fqdn: `hostname -I | awk '{print $1}'`.nip.io
" > /etc/assemblyline/config.yml

# Install VSCode
if [ $code ]
then
  sudo sysctl -w fs.inotify.max_user_watches=524288
  sudo snap install code --classic
fi

# Start with cloning repositories
git clone git@github.com:CybercentreCanada/assemblyline-base.git || git clone https://github.com/CybercentreCanada/assemblyline-base.git
git clone git@github.com:CybercentreCanada/assemblyline-core.git || git clone https://github.com/CybercentreCanada/assemblyline-core.git
git clone git@github.com:CybercentreCanada/assemblyline-service-server.git || git clone https://github.com/CybercentreCanada/assemblyline-service-server.git
git clone git@github.com:CybercentreCanada/assemblyline-ui.git || git clone https://github.com/CybercentreCanada/assemblyline-ui.git
git clone git@github.com:CybercentreCanada/assemblyline_client.git || git clone https://github.com/CybercentreCanada/assemblyline_client.git
git clone git@github.com:CybercentreCanada/assemblyline-service-client.git || git clone https://github.com/CybercentreCanada/assemblyline-service-client.git
git clone git@github.com:CybercentreCanada/assemblyline-v4-service.git || git clone https://github.com/CybercentreCanada/assemblyline-v4-service.git

# Setup dependencies
sudo apt-get update
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt-get install -yy python3-venv python3.9 python3.9-dev python3.9-venv libffi7
sudo apt-get install -yy libfuzzy2 libmagic1 libldap-2.4-2 libsasl2-2 build-essential libffi-dev libfuzzy-dev libldap2-dev libsasl2-dev libssl-dev

# Allow connections to github.com via SSH
ssh-keyscan github.com >> ~/.ssh/known_hosts

# Setup venv
python3.9 -m venv venv
venv/bin/pip install -U pip
venv/bin/pip install -U wheel
venv/bin/pip install -U pytest pytest-cov fakeredis[lua] retrying codecov flake8 pep8 autopep8 ipython
venv/bin/pip install -e ./assemblyline-base
venv/bin/pip install -e ./assemblyline-core
venv/bin/pip install -e ./assemblyline-service-server
venv/bin/pip install -e ./assemblyline-service-client
venv/bin/pip install -e ./assemblyline-ui
venv/bin/pip install -e ./assemblyline-v4-service
venv/bin/pip install -e ./assemblyline_client

# Remove temporary created file during install
rm -rf assemblyline-base/assemblyline/common/frequency.c

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

# Deploy local Docker registry
sudo docker run -dp 32000:5000 --restart=always --name registry registry

# Setup Kubernetes
if [ $kubernetes ]
then
    # Kubernetes Setup

    # (Offline installation)
    # sudo snap download microk8s
    # sudo snap ack microk8s_*.assert
    # sudo snap install microk8s_*.snap --classic
    # sudo rm -f microk8s_*.*
    echo "Setting up Kubernetes Development Setup ..."
    sudo snap install microk8s --classic

    # Add user to microk8s group
    sudo usermod -a -G microk8s $USER
    sudo chown -f -R $USER ~/.kube

    # Grab current directory
    cwd=`pwd`

    # Pre-requisites from appliance setup
    sudo mkdir /var/snap/microk8s/current/bin
    sudo snap install kubectl --classic
    sudo ln -s /snap/bin/kubectl /var/snap/microk8s/current/bin/kubectl
    sudo snap install helm --classic
    sudo ln -s /snap/bin/helm /var/snap/microk8s/current/bin/helm
    sudo microk8s start
    sudo microk8s enable dns ha-cluster storage metrics-server

    # Build dev image and push to local registry
    sudo docker build . -f assemblyline-base/docker/al_dev/Dockerfile -t localhost:32000/cccs/assemblyline:dev
    sudo docker push localhost:32000/cccs/assemblyline:dev

    # Kubernetes directory in Project
    mkdir k8s && cd ./k8s
    git clone git@github.com:CybercentreCanada/assemblyline-helm-chart.git || git clone https://github.com/CybercentreCanada/assemblyline-helm-chart.git
    mkdir deployment
    cp ../.kubernetes/*.yaml ./deployment

    #Overwrite launch & tasks JSON
    cp -f $cwd/.kubernetes/*.json $cwd/.vscode/

    sed -i "s|placeholder/config|$HOME/.kube/config|" $cwd/.vscode/settings.json
    sed -i "s|placeholder_for_packages|$cwd|" $cwd/k8s/deployment/values.yaml
    sed -i 's|// KUBERNETES|"ms-kubernetes-tools\.vscode-kubernetes-tools",\n"mindaro\.mindaro"|' $cwd/.vscode/extensions.json 

    # Deploy an ingress controller
    sudo microk8s kubectl create ns ingress
    sudo microk8s helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    sudo microk8s helm repo update
    sudo microk8s helm install ingress-nginx ingress-nginx/ingress-nginx --set controller.hostPort.enabled=true -n ingress

    # Deploy Assemblyline
    sudo microk8s kubectl create namespace al
    sudo microk8s kubectl apply -f ./deployment/secrets.yaml --namespace=al
    sudo microk8s helm install assemblyline ./assemblyline-helm-chart/assemblyline -f ./deployment/values.yaml -n al

    # Additional steps for development
    sudo mkdir $HOME/.kube/
    sudo cp /var/snap/microk8s/current/credentials/client.config $HOME/.kube/config
    sudo chmod -R 777 $HOME/.kube/

    # Install Lens
    sudo snap install kontena-lens --classic

    # Return to directory
    cd $cwd
fi

if [ $services ]
then
  echo "Setting up services ..."

  # Grab current directory
  cwd=`pwd`

  # Creating services directory
  mkdir -p ../services
  mv .vscode_services ../services/.vscode
  cd ../services

  # Setting up services venv
  python3.9 -m venv venv
  venv/bin/pip install -U pip
  venv/bin/pip install -U wheel

  # Install vscode extension dependencies
  venv/bin/pip install -U pytest pytest-cov codecov flake8 pep8 autopep8 ipython

  # Install AL tests dependencies
  venv/bin/pip install -U packaging fakeredis[lua] retrying gitpython faker requests_mock hachoir mwcp

  # Link services to checkout core components
  venv/bin/pip install -e $cwd/assemblyline-base
  venv/bin/pip install -e $cwd/assemblyline-core
  venv/bin/pip install -e $cwd/assemblyline-service-client
  venv/bin/pip install -e $cwd/assemblyline-v4-service

  # Remove temporary created file during install
  rm -rf $cwd/assemblyline-base/assemblyline/common/frequency.c

  # Clone git repos
  git clone git@github.com:CybercentreCanada/assemblyline-service-antivirus.git || git clone https://github.com/CybercentreCanada/assemblyline-service-antivirus.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-apkaye.git || git clone https://github.com/CybercentreCanada/assemblyline-service-apkaye.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-avclass.git || git clone https://github.com/CybercentreCanada/assemblyline-service-avclass.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-beaver.git || git clone https://github.com/CybercentreCanada/assemblyline-service-beaver.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-characterize.git || git clone https://github.com/CybercentreCanada/assemblyline-service-characterize.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-configextractor.git || git clone https://github.com/CybercentreCanada/assemblyline-service-configextractor.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-cuckoo.git || git clone https://github.com/CybercentreCanada/assemblyline-service-cuckoo.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-deobfuscripter.git || git clone https://github.com/CybercentreCanada/assemblyline-service-deobfuscripter.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-emlparser.git || git clone https://github.com/CybercentreCanada/assemblyline-service-emlparser.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-espresso.git || git clone https://github.com/CybercentreCanada/assemblyline-service-espresso.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-extract.git || git clone https://github.com/CybercentreCanada/assemblyline-service-extract.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-floss.git || git clone https://github.com/CybercentreCanada/assemblyline-service-floss.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-frankenstrings.git || git clone https://github.com/CybercentreCanada/assemblyline-service-frankenstrings.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-iparse.git || git clone https://github.com/CybercentreCanada/assemblyline-service-iparse.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-metadefender.git || git clone https://github.com/CybercentreCanada/assemblyline-service-metadefender.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-metapeek.git || git clone https://github.com/CybercentreCanada/assemblyline-service-metapeek.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-oletools.git || git clone https://github.com/CybercentreCanada/assemblyline-service-oletools.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-pdfid.git || git clone https://github.com/CybercentreCanada/assemblyline-service-pdfid.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-peepdf.git || git clone https://github.com/CybercentreCanada/assemblyline-service-peepdf.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-pefile.git || git clone https://github.com/CybercentreCanada/assemblyline-service-pefile.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-pixaxe.git || git clone https://github.com/CybercentreCanada/assemblyline-service-pixaxe.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-safelist.git || git clone https://github.com/CybercentreCanada/assemblyline-service-safelist.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-sigma.git || git clone https://github.com/CybercentreCanada/assemblyline-service-sigma.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-suricata.git || git clone https://github.com/CybercentreCanada/assemblyline-service-suricata.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-swiffer.git || git clone https://github.com/CybercentreCanada/assemblyline-service-swiffer.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-torrentslicer.git || git clone https://github.com/CybercentreCanada/assemblyline-service-torrentslicer.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-unpacker.git || git clone https://github.com/CybercentreCanada/assemblyline-service-unpacker.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-unpacme.git || git clone https://github.com/CybercentreCanada/assemblyline-service-unpacme.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-vipermonkey.git || git clone https://github.com/CybercentreCanada/assemblyline-service-vipermonkey.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-virustotal-dynamic.git || git clone https://github.com/CybercentreCanada/assemblyline-service-virustotal-dynamic.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-virustotal-static.git || git clone https://github.com/CybercentreCanada/assemblyline-service-virustotal-static.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-XLMMacroDeobfuscator.git || git clone https://github.com/CybercentreCanada/assemblyline-service-XLMMacroDeobfuscator.git
  git clone git@github.com:CybercentreCanada/assemblyline-service-yara.git || git clone https://github.com/CybercentreCanada/assemblyline-service-yara.git

  # Return to directory
  cd $cwd
fi

# Self destruct!
rm -rf .git*
rm -rf setup_vscode.sh
rm -rf .kubernetes
rm -rf README.md
rm -rf .vscode_services

echo "Setup script execution complete. Press enter to reboot..."
read
sudo reboot
