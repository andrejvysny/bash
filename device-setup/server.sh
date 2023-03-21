#!/bin/bash

sudo apt update
sudo apt upgrade
sudo apt install htop curl wget
# Create user
username="andrejvysny"
sudo adduser --shell /bin/bash $username
sudo chown $username:$username /home/$username
sudo chmod 700 /home/$username
sudo su - $username
# Bash aliases

# SSH
curl -sSL https://get.andrejvysny.sk/ssh/id_rsa.pub >> /home/andrejvysny/.ssh/authorized_keys

# Install docker
curl -sSL https://get.docker.com | sh
sudo groupadd docker
sudo usermod -aG docker $username
docker version