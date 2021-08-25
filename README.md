# Assemblyline 4 - Dev environment setup

This repo will set you up with everything required to do dev on Assemblyline 4 core using VSCode. It will setup for you the following things:

- Install AL4 development dependencies (Docker-Compose & Kubernetes)
- Create a virtual python environment for your project
- Create Run targets inside VSCode for all core components and other important scripts
- Create Tasks inside VSCode for development using Docker-Compose & Kubernetes
- Setup our code formatting standards
- Deploy a local Docker registry on port 32000
- (Optional) Install microK8S and deploy a small cluster which will be stopped so you can start it at your convenience

We recommend installing the VSCode extensions needed to use this environment

## Pre-requisites

The setup vscode environment script assumes the following:

- You are running this on a Ubuntu machine / VM (20.04 and up)
- VSCode does not have to be running on the same host were you run this script so you can run this setup script on the target VM of a remote development setup
- You have read the setup_vscode.sh script, this script will install and configure packages for ease of use.
  - **If you are uncomfortable which some of the changes that it makes, you should comment them before running the script.**

## Installation instruction

    # Create your repo directory
    mkdir -p ~/git
    cd ~/git

    # Clone repo
    git clone https://github.com/CybercentreCanada/assemblyline-development-setup alv4

    # Run script
    cd alv4
    bash ./setup_vscode.sh

## Post-installation instructions

When installation is done, just open VSCode and point it to the alv4 folder. VSCode may recommend you some extensions, if so you should definitely install them as this is the only way you will be able to take full advantage of all the features that we've prebuilt in this setup.
