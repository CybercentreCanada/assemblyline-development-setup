# Assemblyline 4 - Dev environment setup

This repo will set you up with everything required to do dev on Assemblyline 4 core using VSCode. It will setup for you the following things:

- Install AL4 development dependencies
- Create a virtual python environment for your project
- Create Run targets inside VSCode for all core components and other important scripts
- Create Tasks inside VSCode to run the various Docker compose files needed for dev
- Setup our code formatting standards
- Recommend you the VSCode extensions needed to use this environment

## Pre-requisites

The setup vscode environment script assumes the following:

- You are running this on a Ubuntu machine / VM (18.04 and up)
- VSCode does not have to be running on the same host were you run this script so you can run this setup script on the target VM of a remote development setup

## Installation instruction

    # Create your repo directory
    mkdir -p ~/git
    cd ~/git

    # Clone repo
    git clone git@github.com:cccs-sgaron/alv4_setup.git alv4

    # Run script
    cd alv4
    ./setup_vscode.sh

## Post-installation instructions

When installation is done, just open VSCode and point it to the alv4 folder. VSCode may recommend you some extensions, if so you should definitely install them as this is the only way you will be able to take full advantage of all the features that we've prebuilt in this setup.
