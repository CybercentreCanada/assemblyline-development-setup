
#!/bin/sh

set -x

# Setup dependencies
sudo apt install python3.8 python3.8-dev python3.8-venv

# Clone git repos
git clone git@github.com:CybercentreCanada/assemblyline-base.git
git clone git@github.com:CybercentreCanada/assemblyline-core.git
git clone git@github.com:CybercentreCanada/assemblyline-service-server.git
git clone git@github.com:CybercentreCanada/assemblyline-ui.git
git clone git@github.com:CybercentreCanada/assemblyline-service-client.git
git clone git@github.com:CybercentreCanada/assemblyline-v4-service.git

# Setup venv
python3.8 -m venv venv
venv/bin/pip install -U pip
venv/bin/pip install -U pytest pytest-cov fakeredis[lua] retrying codecov pylint pep8 autopep8 ipython
venv/bin/pip install -e ./assemblyline-base
venv/bin/pip install -e ./assemblyline-core
venv/bin/pip install -e ./assemblyline-service-server
venv/bin/pip install -e ./assemblyline-service-client
venv/bin/pip install -e ./assemblyline-ui
venv/bin/pip install -e ./assemblyline-v4-service

rm -rf assemblyline-base/assemblyline/common/frequency.c

# Self destruct!
rm -rf .git
rm -rf setup_vscode.sh
rm -rf README.md
