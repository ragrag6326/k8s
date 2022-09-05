#!/bin/bash

# P1. 下載 & 安裝 tools for cri-o

sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common

    # Export Version 
    export OS_VERSION=xUbuntu_22.04
    export CRIO_VERSION=1.24
    export KUBE_VER=1.24.2-00

# P2. cri & k8s 安裝設定
    #  GPG key for cri-o  下載指定版本
        sudo curl -fsSL https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS_VERSION/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-archive-keyring.gpg
        sudo curl -fsSL https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$OS_VERSION/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg

    # add cri-o repository
        sudo echo "deb [signed-by=/usr/share/keyrings/libcontainers-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS_VERSION/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
        sudo echo "deb [signed-by=/usr/share/keyrings/libcontainers-crio-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$OS_VERSION/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.list

    # Add k8s repository
        sudo echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

    # 更新 repository
        sudo apt-get update

    # cri-o & k8s 使用相同版本 
        sudo apt-get install -y cri-o cri-o-runc kubelet=${KUBE_VER} kubeadm=${KUBE_VER} kubectl=${KUBE_VER}

    # 啟動 cri-o 服務   
        sudo systemctl daemon-reload
        sudo systemctl enable crio
        sudo systemctl start crio

    # 保持套件版本，避免發生問題
        sudo apt-mark hold cri-o kubelet kubeadm kubectl

    # 啟用 modules  開啟iptable bridge
        cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
        overlay
        br_netfilter
        EOF


        cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
        net.bridge.bridge-nf-call-iptables  = 1
        net.bridge.bridge-nf-call-ip6tables = 1
        net.ipv4.ip_forward                 = 1
        EOF

        sudo sysctl --system

    
    sudo kubeadm init --control-plane-endpoint=${KUBE_VIP}:6443 --pod-network-cidr=${POD_CIDR} --service-cidr=${SVC_CIDR} --service-dns-domain=k8s.org --cri-socket=/var/run/crio/crio.sock --upload-certs --v=5











