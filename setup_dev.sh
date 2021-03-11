
#!/bin/bash

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
source venv/bin/activate
pip install -U pip
pip install -U pytest pytest-cov fakeredis[lua] retrying codecov pylint pep8 autopep8 ipython
pip install -e ./assemblyline-base
pip install -e ./assemblyline-core
pip install -e ./assemblyline-service-server
pip install -e ./assemblyline-service-client
pip install -e ./assemblyline-ui
pip install -e ./assemblyline-v4-service

rm -rf assemblyline-base/assemblyline/common/frequency.c

# Self destruct!
rm -rf .git
rm -rf setup_dev.sh
