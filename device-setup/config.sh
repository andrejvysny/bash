#!/bin/bash

SNAP_APPS=( 
    "phpstorm --classic"
    "clion --classic"
    "code --classic"
    slack
    spotify
    vlc
 )

APT_APPS="curl wget git telegram-desktop openvpn build-essential "

SSH_PRIVATE_KEY_FILE="/home/$USER/.ssh/id_rsa"
SSH_TYPE="rsa"

GITHUB_ACCESS_TOKEN=""
GITHUB_USER="andrejvysny"
GIT_NAME="Andrej Vyšný"