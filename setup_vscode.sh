#!/bin/sh -x

usage() { echo "Usage: $0 [-h] [-s]" 1>&2; exit 1; }

# Get command line options
while getopts "sh" arg; do
  case $arg in
    s) # Setup services as well
      services="yes"
      ;;
    h) # Show usage
      usage
      ;;
  esac
done

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
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt-get install -yy python3-venv python3.9 python3.9-dev python3.9-venv libffi7
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

# Remove temporary created file during install
rm -rf assemblyline-base/assemblyline/common/frequency.c

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
rm -rf README.md
rm -rf .vscode_services
