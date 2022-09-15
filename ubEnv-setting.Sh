#! /bin/bash

# P1. 修改 sudo 免密碼 & ssh 登入詢問
  
  sudo sed -i "s/%sudo\tALL=(ALL:ALL) ALL/%sudo\tALL=(ALL:ALL) NOPASSWD: ALL/g" /etc/sudoers
  echo 'StrictHostKeyChecking no' | sudo tee -a /etc/ssh/ssh_config
 
# P2. 環境設定
    sudo apt install net-tools -y
    # 確認網卡
        export NIC=`ifconfig | grep 'flags' | cut -d ':' -f 1 | grep -v 'lo' | grep 'en'`
    # 現在IP 
        export IP=`ip a | grep 'ens' | grep 'inet' | awk '{ print $2 }' | cut -d '.' -f 1-3`
    # GATEWAY
        export GW=`route -n | grep 'ens' | tr -s ' ' | cut -d ' ' -f 2 | head -n 1`
    # Netmask
        export NM=`ip a | grep inet | grep "$NIC" | awk '{ print $2 }' | cut -d '/' -f 2`
    # 固定 IP 設定
        export m1IP=130
        export w1IP=132
        export w2IP=133

# P2. hosts 解析 
  clear
  sudo cat /etc/hosts | grep "$IP"
if [ $? != 0 ] ; then
  cat <<EOF | sudo tee -a /etc/hosts 

$IP.$m1IP m1
$IP.$w1IP w1
$IP.$w2IP w2
EOF
else
    echo "hosts setting alreday" 
fi
    echo "--Make sure hosts setting correct if not interrupt it--"
    read -p "-- Continue after any key --"
clear


  # 主機名稱修改 
  echo "[ m1 | w1 | w2 ]"
  read -p "Select your node-name": hostname
cat <<EOF | sudo tee /etc/hostname > /dev/null 
$hostname
EOF

export hn=`sudo cat /etc/hostname` 
if [ "$hn" = "$hostname" ] ; then
  echo " $hostname correct" ; sleep 3
else
  echo "$hostname not correct check again"  
  sleep 3 ; exit
fi
    # w1 、 w2 主機 請重新設定 /etc/hostname 

# m1 主機
export hn=`sudo cat /etc/hostname` 
  if [ $hn = "m1" ] ; then
cat <<EOF | sudo tee /etc/netplan/00-installer-config.yaml > /dev/null
# This is the network config written by 'subiquity'
network:
  ethernets:
    $NIC:
      dhcp4: no
      dhcp6: no
      addresses: [$IP.$m1IP/$NM]
      routes :
      - to: default
        via : $GW
      nameservers:
        addresses: [168.95.1.1,8.8.8.8]
  version: 2
EOF
   # ssh 公私鑰匙複製給自己 
  sudo rm -r ${HOME}/.ssh/*
  echo | ssh-keygen -P '' 
  user=$(id -urn)
  echo " 請輸入密碼 "
  ssh-copy-id $user@localhost
  echo "$hn IP Setting OK" , "$hn ssh key copy ok"; sleep 3 ; sudo netplan apply > /dev/null
fi



# w1 主機
if [ $hn = "w1" ] ; then
cat <<EOF | sudo tee /etc/netplan/00-installer-config.yaml > /dev/null
# This is the network config written by 'subiquity'
network:
  ethernets:
    $NIC:
      dhcp4: no
      dhcp6: no
      addresses: [$IP.$w1IP/$NM]
      routes :
      - to: default
        via : $GW
      nameservers:
        addresses: [168.95.1.1,8.8.8.8]
  version: 2
EOF
clear ; scp m1:.ssh/* ${HOME}
echo "$hn IP Setting OK" ; "$hn ssh key copy ok" ; sleep 3
sudo netplan apply > /dev/null 
else
echo "please setting hostname if ur Workernode is w1"
fi


# w2 主機
if [ $hn = "w2" ] ; then
cat <<EOF | sudo tee /etc/netplan/00-installer-config.yaml > /dev/null
# This is the network config written by 'subiquity'
network:
  ethernets:
    $NIC:
      dhcp4: no
      dhcp6: no
      addresses: [$IP.$w2IP/$NM]
      routes :
      - to: default
        via : $GW
      nameservers:
        addresses: [168.95.1.1,8.8.8.8]
  version: 2
EOF
echo " $hn IP Setting OK" ; "$hn ssh key copy ok" ; sleep 3
sudo netplan apply > /dev/null 
else
echo "please setting hostname if ur Workernode is w2"
fi


