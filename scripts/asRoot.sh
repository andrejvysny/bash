#!/bin/bash

# Check if script is executing as root
if [ "$EUID" -ne 0 ]
  then echo -e "\n${White}${On_Red} Please run as root! ${Color_Off}\n"
  exit
fi