#!/bin/bash

SNAP_APPS=( 
    "code --classic"
    slack
    discord
    spotify
    vlc
 )

APT_APPS="wget git telegram-desktop htop openvpn build-essential "

SSH_PRIVATE_KEY_FILE="/home/$USER/.ssh/id_rsa"
SSH_TYPE="rsa"

GITHUB_ACCESS_TOKEN=""
GITHUB_USER="andrejvysny"
GIT_NAME="Andrej Vyšný"
