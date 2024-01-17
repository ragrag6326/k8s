#!/bin/bash

export NIC=`ifconfig | grep 'flags' | cut -d ':' -f 1  | grep 'en'`
export IP=`ip a | grep "$NIC" | grep 'inet' | awk '{ print $2 }' | cut -d '.' -f 1-3`

# https://metallb.universe.tf/installation/
# 必須啟用嚴格 ARP 模式
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system


# 安裝 MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml



# https://metallb.universe.tf/configuration/
# Layer 2 配置 (第 2 層模式配置最簡單：在許多情況下，您不需要任何特定於協定的配置，只需要 IP 位址。 )


echo '
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - $IP.10-$IP.11 | kubectl apply -f -