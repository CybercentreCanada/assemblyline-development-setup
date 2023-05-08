# Assemblyline 4 - Dev environment setup

This repo will setup everything required to do development on Assemblyline 4 using VSCode. It will setup for you the following things:

- Install VSCode via snap
- Install AL4 development dependencies
- Create a virtual python environment for your project
- Create Run targets inside VSCode for all core components and other important scripts
- Create Tasks inside VSCode for development using Docker-Compose
- Setup our code formatting standards
- Deploy a local Docker registry on port 32000
- (*Optional*) Load the code for all services in the git/services directory by using the `-s` flag. **This is not recommended, use only if you really need to.**
- (*Optional*) If you prefer to run VSCode on your host and not on the dev machine/VM remove the `-c` flag so VSCode does not get installed. You'll have to install VSCode yourself on your desktop and connect to your dev environment via SSH.

We recommend installing the VSCode extensions needed to use this environment once VSCode is launched in the workspace.

## Pre-requisites

The setup script assumes the following:

- You are running this on a Ubuntu 20.04+ machine or VM with at least 4 cores and 8 GB of Ram. 
- You have read the setup_vscode.sh script, this script will install and configure packages for ease of use.
  - **If you are uncomfortable which some of the changes that it makes, you should comment them before running the script.**

## Installation instruction

#### Create your git directory

    mkdir -p ~/git

#### Clone repo

    cd ~/git
    git clone https://github.com/CybercentreCanada/assemblyline-development-setup alv4

#### Run setup script 

    cd ~/git/alv4
    ./setup_vscode.sh -c

## Post-installation instructions

When first launching VSCode, we strongly advise installing the recommended extensions when prompted or typing '@recommended' in the Extensions tab. This ensures that you take full advantage of this setup.
