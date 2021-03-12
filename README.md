# Assemblyline 4 - Dev environment setup

This repo will set you up with everything required to do dev on Assemblyline 4 core using VSCode. It will setup for you the following things:

- Install all dependencies
- Create a virtual python environment for your project
- Create Run targets inside VSCode for all core components and other important scripts
- Create Tasks to run the various Docker compose files needed for dev
- Setup all our code formatting standards
- Recommend you the extensions need to perform all the tasks

## Pre-requisites

The setup vscode environment script assumes the following:

- You are running this on a Ubuntu machine / VM
- VSCode does not have to be running on the same host were you run this script

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

When installation is done, just open VSCode on the alv4 folder. VSCode may recommend you some extensions, if so you should definitely install them as this is the only way you will be able to take full advantage of all the features that we've prebuilt in this setup.
