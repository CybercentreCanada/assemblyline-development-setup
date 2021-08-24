#!/bin/bash -x

echo "Welcome to the Assemblyline Developer Setup!"
echo "1. Which repositories would you like to setup?
    a. Core + Services (Default)
    b. Services
    c. Core"
read repositories
repositories="${repositories:=a}"

echo "2. Which debugging infrastructure do you want to use?
    a. Kubernetes via microK8S
    b. Docker-Compose (Default)"
read infrastructure
infrastructure="${infrastructure:=a}"

offline="no"
if [ "$infrastructure" == "a" ]
then
echo "2a. Offline deployment of microK8S? (yes/no)"
read offline
offline="${offline:=no}"
fi

echo "3. Would you like to setup all official services? (yes/no)"
read services
services="${services:=no}"

echo "Options Summary:
1. Which repositories would you like to setup? Option $repositories
2. Which debugging infrastructure do you want to use? Option $infrastructure
3. Would you like to setup all official services? $services"
read -n 1 -p "Continue?"

# Prepare sysctl for VSCode
sudo sysctl -w fs.inotify.max_user_watches=524288

# Start with cloning repositories
# Clone for Core
if [ "$repositories" = "a" ] || [ "$repositories" = "c" ]
then
    git clone git@github.com:CybercentreCanada/assemblyline-base.git || git clone https://github.com/CybercentreCanada/assemblyline-base.git
    git clone git@github.com:CybercentreCanada/assemblyline-core.git || git clone https://github.com/CybercentreCanada/assemblyline-core.git
    git clone git@github.com:CybercentreCanada/assemblyline-service-server.git || git clone https://github.com/CybercentreCanada/assemblyline-service-server.git
    git clone git@github.com:CybercentreCanada/assemblyline-ui.git || git clone https://github.com/CybercentreCanada/assemblyline-ui.git
    git clone git@github.com:CybercentreCanada/assemblyline_client.git || git clone https://github.com/CybercentreCanada/assemblyline_client.git
fi

# Clone for Services
if [ "$repositories" = "a" ] || [ "$repositories" = "b" ]
then
    git clone git@github.com:CybercentreCanada/assemblyline-service-client.git || git clone https://github.com/CybercentreCanada/assemblyline-service-client.git
    git clone git@github.com:CybercentreCanada/assemblyline-v4-service.git || git clone https://github.com/CybercentreCanada/assemblyline-v4-service.git
fi

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

# Docker-Compose Setup
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

# Setup Kubernetes
if [ "$infrastructure" = "a" ]
then
    # Kubernetes Setup
    echo "Setting up Kubernetes Development Setup ..."
    if [ "$offline" == "yes" ]
    then
        sudo snap download microk8s
        sudo snap ack microk8s_*.assert
        sudo snap install microk8s_*.snap
        sudo rm -f microk8s_*.*
    else
        sudo snap install microk8s --classic
    fi

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
    sudo microk8s enable dns ha-cluster storage metrics-server registry

    # Build dev image and push to local registry
    sudo docker build . -f assemblyline-base/docker/al_dev/Dockerfile -t localhost:32000/cccs/assemblyline:dev
    sudo docker push localhost:32000/assemblyline:dev

    # Kubernetes directory in Project
    mkdir k8s && cd ./k8s
    git clone https://github.com/CybercentreCanada/assemblyline-helm-chart.git
    mkdir deployment
    cp ../helm_deployment/*.yaml ./deployment

    sed -i "s|placeholder/config|$HOME/.kube/config|" $cwd/.vscode/settings.json
    sed -i "s|placeholder_for_packages|$cwd|" $cwd/k8s/deployment/values.yaml



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

    # Let user start up the cluster if they want to
    sudo microk8s stop

    # Install Lens
    sudo snap install kontena-lens --classic

    # Return to directory
    cd $cwd
fi

if [ "$services" == "yes" ]
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
rm -rf helm_deployment
rm -rf README.md
rm -rf .vscode_services
