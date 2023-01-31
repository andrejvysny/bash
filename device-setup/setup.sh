#!/bin/bash

[ -f "./config.sh" ] && source config.sh || source https://raw.githubusercontent.com/andrejvysny/bash/main/device-setup/config.sh

source https://raw.githubusercontent.com/andrejvysny/bash/main/core/colors.sh
source https://raw.githubusercontent.com/andrejvysny/bash/main/core/asRoot.sh

# Starting Script
apt update
apt upgrade
apt install $APT_APPS

git config --global user.name $GIT_NAME

# Install Google Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg -i google-chrome-stable_current_amd64.deb


# Install Snap Applications
for APP in "${SNAP_APPS[@]}"
do
	snap install $APP
done

# Docker
curl -sSL https://get.docker.com | sh
groupadd docker
usermod -aG docker $USER

docker login ghcr.io -u $GITHUB_USER -p $GITHUB_ACCESS_TOKEN

# Create and Store SSH key
[ ! -f "${SSH_PRIVATE_KEY_FILE}.pub" ] && ssh-keygen -q -f $SSH_PRIVATE_KEY_FILE -N "" -t $SSH_TYPE || echo "SSH key found!"
SSH_PUB=$(< ${SSH_PRIVATE_KEY_FILE}.pub)


# Final Summary 
echo -e "\n${Black}${On_Green} FINISHED ${Color_Off}\n"

echo -e "\n${Black}${On_Yellow} Reboot is Needed, to apply some changes! ${Color_Off}\n"

echo -e "\n${Black}${On_Cyan} Your SSH Public key: ${Color_Off}\n\n $SSH_PUB \n\n"