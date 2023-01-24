#!/bin/bash
apt update
apt upgrade
apt install curl wget git telegram-desktop
snap install slack
snap install phpstorm --classic
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg -i google-chrome-stable_current_amd64.deb
curl -sSL https://get.docker.com | sh
groupadd docker
sudo usermod -aG docker $USER
