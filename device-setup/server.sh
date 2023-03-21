#!/bin/bash

apt update
apt upgrade -y
apt install htop curl wget -y

# Bash aliases

# SSH
curl -sSL https://get.andrejvysny.sk/ssh/id_rsa.pub >> /home/andrejvysny/.ssh/authorized_keys

# Install docker
curl -sSL https://get.docker.com | sh
sudo groupadd docker
sudo usermod -aG docker $USER
docker version