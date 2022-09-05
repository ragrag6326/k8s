#! /bin/bash

# P1. 修改 sudo不用打密碼  /etc/sudoers 
# (非root)建議手動修改
# cat /etc/sudoers | sed '50 s/%sudo   ALL=(ALL:ALL) ALL/%sudo   ALL=(ALL:ALL) NOPASSWD:ALL/g' > /etc/sudoers

# P2. hosts 解析 
sudo cp /etc/hosts ~/
export name=`id -urn`
sudo chown $name:$name ~/hosts
sudo echo -e " 
192.168.91.130 m1
192.168.91.132 w1
192.168.91.133 w2"  >> ~/hosts
sudo chown root:root ~/hosts

sudo cp ~/hosts /etc/hosts
sudo rm hosts 

    # m1 主機名稱修改 
cat <<EOF | sudo tee /etc/hostname > /dev/null
m1
EOF
fi
    # w1 、 w2 主機 請重新設定 /etc/hostname 

# P3. 環境設定
    sudo apt install net-tools -y
    # 確認網卡
        export NIC=`ifconfig | grep 'flags' | cut -d ':' -f 1 | grep -v 'lo'`
    # 現在IP 
        export IP=`ip a | grep 'ens' | grep 'inet' | awk '{ print $2 }' | cut -d '/' -f 1`
    # GATEWAY
        export GW=`route -n | grep 'ens' | tr -s ' ' | cut -d ' ' -f 2 | head -n 1`
    # Netmask
        export NM=`ip a | grep inet | grep "$NIC" | awk '{ print $2 }' | cut -d '/' -f 2`


    # 固定 IP 設定
m1IP="192.168.91.130"
w1IP="192.168.91.132"
w2IP="192.168.91.133"

        # m1 主機
sudo cat /etc/hostname 
if [ $? = m1 ] ; then
cat <<EOF | sudo tee /etc/netplan/00-installer-config.yaml > /dev/null
network:
  ethernets:
    $NIC:
      addresses: [$m1IP/$NM]
      gateway4: $GW
      nameservers:
        addresses: [168.95.1.1,8.8.8.8]
  version: 2
EOF
fi

        # w1 主機
sudo cat /etc/hostname 
if [ $? = w1 ] ; then
cat <<EOF | sudo tee /etc/netplan/00-installer-config.yaml > /dev/null
network:
  ethernets:
    $NIC:
      addresses: [$w1IP/$NM]
      gateway4: $GW
      nameservers:
        addresses: [168.95.1.1,8.8.8.8]
  version: 2
EOF
fi

        # w2 主機
sudo cat /etc/hostname 
if [ $? = w2 ] ; then
cat <<EOF | sudo tee /etc/netplan/00-installer-config.yaml > /dev/null
network:
  ethernets:
    $NIC:
      addresses: [$w2IP/$NM]
      gateway4: $GW
      nameservers:
        addresses: [168.95.1.1,8.8.8.8]
  version: 2
EOF
fi

sudo netplan apply
















