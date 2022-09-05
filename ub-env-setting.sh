#! /bin/bash

# P1. sudo NOPASSWD  /etc/sudoers 
cat <<EOF | sudo tee /etc/sudoers | sed "s|%sudo   ALL=(ALL:ALL) ALL|%sudo   ALL=(ALL:ALL) NOPASSWD:ALL|g" 
EOF