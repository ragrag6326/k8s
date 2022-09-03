#! /bin/bash

#---------------------------------------
#  基本變數宣告

# package
export OS=xUbuntu_20.04
# Get OS Version $(echo "x`cat /etc/os-release | grep 'PRETTY_NAME' | cut -d '"' -f 2 | tr -s ' ' '_' | cut -d '.' -f 1-2`")
export CRI_VER=1.24
export KUBE_VER=1.24.3-00
# network
export IP=`ip a | grep 'en' | grep 'inet' | awk '{ print $2 }' | cut -d '/' -f 1 | head -n 1`
export NETID=`ip a | grep 'en' | grep 'inet' | awk '{ print $2 }' | cut -d '.' -f 1-3 | head -n 1`
export GATEWAY=`route -n | tr -s " " | grep 'en' | cut -d " " -f 2 | grep "${NETID}"`
export NETMASK=`route -n | grep 'en' | grep -w 'U' | awk '{ print $3 }'`
# Kube-VIP
export VIP_TARGET=$(($(cat /etc/hosts | grep m1 | awk '{ print $1 }' | cut -d '.' -f 4)-1))
export KUBE_VIP="${NETID}.${VIP_TARGET}"
export KUBE_INTERFACE=$(ip r | grep "${IP}" | awk '{ print $3 }')
# node & service
m_nodes=$(cat /etc/hosts | grep -v "#" | grep "$NETID" | awk '{ print $2 }' | grep "m" | tr -s '\n' ' ')
w_nodes=$(cat /etc/hosts | grep -v "#" | grep "$NETID" | awk '{ print $2 }' | grep "w" | tr -s '\n' ' ')
init_master=$(echo ${m_nodes} | awk '{ print $1 }')
# -----------------------------------


# P1. kube vip安裝
# /etc/kubernetes/manifests/kube-vip-arp.yaml
wget -O - https://raw.githubusercontent.com/kube-vip/kube-vip/main/docs/manifests/v0.4.1/kube-vip-arp.yaml 
| sed "s|eth0|${KUBE_INTERFACE}|g" 
| sed "s|192.168.0.1|${KUBE_VIP}|g" 
| sed "s|imagePullPolicy\: Always|imagePullPolicy\: IfNotPresent|g" 
| sudo tee /etc/kubernetes/manifests/kube-vip-arp.yaml


# P2. install podman
echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/ /' | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list

curl -fsSL https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_20.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/devel_kubic_libcontainers_stable.gpg > /dev/null

sudo apt-get update
sudo apt-get install podman


# P3.  
















