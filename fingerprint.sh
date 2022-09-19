#!/bin/bash

sudo apt update
sudo apt upgrade

#http://dell.archive.canonical.com/updates/pool/public/libf/libfprint-2-tod1-goodix/libfprint-2-tod1-goodix_0.0.6-0ubuntu1~somerville1_amd64.deb
#http://dell.archive.canonical.com/updates/pool/public/libf/libfprint-2-tod1-goodix/
sudo apt install fprintd



sudo pam-auth-update
#Enable Fingerprint auth
