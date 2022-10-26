#! /bin/bash

# P1. 修改 sudo 免密碼 & ssh 登入詢問
  
  sudo sed -i "s/%sudo\tALL=(ALL:ALL) ALL/%sudo\tALL=(ALL:ALL) NOPASSWD: ALL/g" /etc/sudoers
  echo 'StrictHostKeyChecking no' | sudo tee -a /etc/ssh/ssh_config
 
# 環境設定
    #   安裝網路套件
        sudo apt install net-tools -y
    # 確認網卡
        export NIC=`ifconfig | grep 'flags' | cut -d ':' -f 1 | grep -v 'lo' | grep 'en'`
    # 現在IP 
        export IP=`ip a | grep 'ens' | grep 'inet' | awk '{ print $2 }' | cut -d '.' -f 1-3`
    # GATEWAY
        export GW=`route -n | grep 'ens' | tr -s ' ' | cut -d ' ' -f 2 | head -n 1`
    # Netmask
        export NM=`ip a | grep inet | grep "$NIC" | awk '{ print $2 }' | cut -d '/' -f 2`
    # 當前作業系統
        export OS_VERSION=$(echo "`cat /etc/os-release | grep 'PRETTY_NAME' | cut -d '"' -f 2`")



clear
while true
do

echo "
[ m1IP:$m1 |w1IP:$w1 |w2IP:$w2 ]
"
read -p " 請選要檢查的 node  IP :
(1) m1
(2) w1
(3) w2
(4) 所有node設定好在選 (4)
: " nodename

case $nodename in

1)
read -p " m1 請選一個IP 1-253 :" m1IP
nc $IP.$m1IP 22 > /dev/null
if [ $? = 0 ] ; then
    echo "$m1IP 此IP有人使用,請換一個" ;sleep 3 ;clear
else
    echo " m1 IP $m1IP 沒人使用" ;sleep 3 ;clear
    export m1=$m1IP
fi

;;

2)
read -p " w1 請選一個IP 1-253 :" w1IP
nc $IP.$w1IP 22 > /dev/null
if [ $? = 0 ] ; then
    echo " $w1IP 此IP有人使用,請換一個" ;sleep 3 ;clear
else
    echo " w1 IP $w1IP  沒人使用" ;sleep 3 ;clear
    export w1=$w1IP
fi

;;

3)
read -p " w2 請選一個IP 1-253 :" w2IP
nc $IP.$w2IP 22 > /dev/null
if [ $? = 0 ] ; then
    echo " $w2IP 此IP有人使用,請換一個" ;sleep 3 ;clear
else
    echo " w2 IP $w2IP  沒人使用" ;sleep 3 ;clear
    export w2=$w2IP
fi

;;

4) break ;;


*)

    esac
done



clear
echo "$OS_VERSION"
read -p "
Choose your operating system :
(1) ubuntu 22.04
(2) Centos 20.04
(3) Exit
:" ans

case $ans in 

1) 

# --------------------- Ubuntu 22.04.1 LTS ---------------------------


#  主機名稱修改 
#  其他主機 , 需要重新執行程式設定 /etc/hostname 

  echo "[ m1 | w1 | w2 ]"
  read -p "Select your node-name": hostname

cat <<EOF | sudo tee /etc/hostname > /dev/null 
$hostname
EOF

export hn=`sudo cat /etc/hostname` 
if [ "$hn" = "$hostname" ] ; then
  echo " hostname is $hostname " ; sleep 3
else
  echo "$hostname setting not correct check again"  
  sleep 3 ; exit
fi


#  hosts 解析 
  clear
  sudo cat /etc/hosts | grep "$IP"
if [ $? != 0 ] ; then
cat <<EOF | sudo tee -a /etc/hosts 
$IP.$m1 m1
$IP.$w1 w1
$IP.$w2 w2
EOF
else
    echo "hosts setting alreday" 
fi

    echo "--Make sure hosts setting correct if not interrupt it--"
    read -p "-- Continue after any key --"
clear







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
   # ssh 公鑰複製給自己 
  sudo rm -r ${HOME}/.ssh/*
  echo | ssh-keygen -P '' 
  user=$(id -urn)
  echo "\n請輸入密碼 "
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
clear 
  echo "$hn IP Setting OK"  ; sleep 3
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
clear
  echo " $hn IP Setting OK"  ; sleep 3
  sudo netplan apply > /dev/null 
else
  echo "please setting hostname if ur Workernode is w2"
fi

;;




2)
# --------------------------- Ubuntu 20.04.3 LTS ---------------------------

#  hosts 解析 
  clear
  sudo cat /etc/hosts | grep "$IP"
if [ $? != 0 ] ; then
cat <<EOF | sudo tee -a /etc/hosts 
$IP.$m1 m1
$IP.$w1 w1
$IP.$w2 w2
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
      addresses: 
      - $IP.$m1/$NM
      gateway4 : $GW
      nameservers:
        addresses: 
        - 8.8.8.8
  version: 2
EOF
   # ssh 公鑰複製給自己 
  sudo rm -r ${HOME}/.ssh/*
  echo | ssh-keygen -P '' 
  user=$(id -urn)
  echo "\n請輸入密碼 "
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
      addresses: 
      - $IP.$w1/$NM
      gateway4 : $GW
      nameservers:
        addresses: 
        - 8.8.8.8
  version: 2
EOF
clear 
  echo "$hn IP Setting OK"  ; sleep 3
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
      addresses: 
      - $IP.$w1/$NM
      gateway4 : $GW
      nameservers:
        addresses: 
        - 8.8.8.8
  version: 2
EOF
clear
  echo " $hn IP Setting OK"  ; sleep 3
  sudo netplan apply > /dev/null 
else
  echo "please setting hostname if ur Workernode is w2"
fi

;;


3) exit ;;


*)

esac
