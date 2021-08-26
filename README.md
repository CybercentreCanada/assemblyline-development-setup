# Assemblyline 4 - Dev environment setup

This repo will setup everything required to do development on Assemblyline 4 using VSCode. It will setup for you the following things:

- Install VSCode via snap
- Install AL4 development dependencies
- Create a virtual python environment for your project
- Create Run targets inside VSCode for all core components and other important scripts
- Create Tasks inside VSCode for development using Docker-Compose
- Setup our code formatting standards
- Deploy a local Docker registry on port 32000

We recommend installing the VSCode extensions needed to use this environment once VSCode is launched in the workspace.

## Pre-requisites

The setup script assumes the following:

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

    # Run script (with services [-s])
    cd alv4
    ./setup_vscode.sh


## Post-installation instructions

When installation is complete, VSCode should launch in the development workspace. To take full advantage of this setup, we strongly advise installing the recommended extensions when prompted or typing '@recommended' in the Extensions tab.
