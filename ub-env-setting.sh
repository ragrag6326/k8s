#! /bin/bash

# P1. sudo NOPASSWD  /etc/sudoers 

sudo cat test | sed '1 s/%sudo   ALL=(ALL:ALL) ALL/%sudo   ALL=(ALL:ALL) NOPASSWD:ALL/g' > /etc/sudoers
