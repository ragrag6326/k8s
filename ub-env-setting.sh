#! /bin/bash

# P1. sudo NOPASSWD  /etc/sudoers 
cat <<EOF | sudo tee /etc/sudoers | sed "s|eth0|${KUBE_INTERFACE}|g" 
EOF