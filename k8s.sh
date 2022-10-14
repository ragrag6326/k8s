#!/bin/bash

# 環境宣告

    # cri & k8s 版本宣告
    export OS_VERSION=xUbuntu_22.04
    export CRI_VER=1.24
    export KUBE_VER=1.24.3-00
    
    # Network
    export NIC=`ifconfig | grep 'flags' | cut -d ':' -f 1  | grep 'en'`
    export IP=`ip a | grep "$NIC" | grep 'inet' | awk '{ print $2 }' | cut -d '.' -f 1-3`
    export GW=`route -n | grep "$NIC" | tr -s ' ' | cut -d ' ' -f 2 | head -n 1`
    export NM=`ip a | grep inet | grep "$NIC" | awk '{ print $2 }' | cut -d '/' -f 2` 

    # node & service
    export master=$(cat /etc/hosts | grep -v "#" | grep "$IP" | awk '{ print $2 }' | grep "m" )
    export nodes=$(cat /etc/hosts | grep -v "#" | grep "$IP" | awk '{ print $2 }' | grep "w" )
    export init_master=$(echo ${master} | awk '{ print $1 }')
    export hn=`sudo cat /etc/hostname` 


# P1. podman 安裝
        echo "--- podman install now ---" ; sleep 2
        sudo podman images > /dev/null
    if [ $? != 0 ] ; then
        echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/ /' | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
        curl -fsSL https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_20.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/devel_kubic_libcontainers_stable.gpg > /dev/null
        sudo apt-get update
        echo -ne "\n" | sudo apt-get install podman
    else
        echo "podman install already" ; sleep 2
    fi
clear

# P2. 系統設定

    # 2-1. 關閉 swap 
        sudo swapoff -a
    
    #註解 swap 內容
    sudo cat /etc/fstab | grep "swap" > /dev/null
    if [ $? = 0 ] ; then
        sudo sed -i '12,/swap/d' /etc/fstab
        echo "----swap off successed----" ; sleep 3
    #確認是否關閉
        sudo swapon --show 
    else
        echo "----swap has been off---- " ; sleep 3
    fi
        clear 
    

    # 2-2. 啟用 modules (iptables bridge)  
    sudo cat /etc/modules | grep "overlay" > /dev/null
if [ $? != 0 ] ; then
cat <<EOF | sudo tee -a /etc/modules > /dev/null
overlay
br_netfilter 
EOF
    sudo modprobe overlay
    sudo modprobe br_netfilter
    
    echo "modules start up" ; sleep 3
else
    echo "modules start up already" ; sleep 3
fi    
    clear

    # 2-3. 設置所需的 sysctl 參數，參數在重新啟動後保持不變
    sudo cat /etc/sysctl.conf | grep "net.bridge" > /dev/null
if [ $? = 0  ] ; then 
    echo "----sysctl.conf setting already---- "
else
    sudo sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g" /etc/sysctl.conf
cat <<EOF | sudo tee -a /etc/sysctl.conf 
net.bridge.bridge-nf-call-iptables = 1    
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF
    echo "---- sysctl.conf setting ok ----" ; sleep 3 
fi
    clear

    # 2.4 關閉 ipv6
        sudo cat /etc/default/grub |grep "ipv6.disable" > /dev/null
    if [ $? != 0 ] ; then
        sudo sed -i "s/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"ipv6.disable=1\"/g" /etc/default/grub
        sudo update-grub
        echo "----ipv6 close successed----" ; sleep 3 
        clear 
    fi 
    # 2.5 應用 sysctl 參數而不重新啟動  (/etc/sysctl.conf)
        sudo sysctl --system
        echo "----sysctl 套用完成----"
        sleep 3 ; clear

# P3. Cri-o 安裝
    cribridge=/etc/cni/net.d/100-crio-bridge.conf
if [ -f $cribridge ] ; then
    echo "----Cri-o file not exist or already exist----" 
    sleep 3 ; clear
else 
    echo "--- Cri-o install now ---" ; sleep 3
    # add cri-o repository
        echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/${OS_VERSION}/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
        echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/${CRI_VER}/${OS_VERSION}/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:${CRI_VER}.list
    clear

    # key for cri-o  下載指定版本
        curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:${CRI_VER}/${OS_VERSION}/Release.key | sudo apt-key add - 
        curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/${OS_VERSION}/Release.key | sudo apt-key add - 
    clear

    # 更新 repository
        sudo apt-get -qy update
    clear
    # 安裝 cri-o 工具
        sudo apt-get -qy install cri-o cri-tools cri-o-runc
    clear

    #  cri-o 設定檔修改 
    clear 
    echo "cri-o 設定檔修改中" ; sleep 2
    sudo cat /etc/crio/crio.conf | grep 'cgroup_manager = \"systemd\"' > /dev/null
if [ $? = 0 ] ; then
    echo "crio.conf setting ok" ; sleep 2
else
# sudo sed -i 's/\[crio.runtime\]/\[crio.runtime\]\nconmon_cgroup = \"pod\"\ncgroup_manager = \"systemd\"\ndefault_runtime = \"crun\"/g' /etc/crio/crio.conf
# sudo sed -i 's/#\[crio.runtime.runtimes.crun\]/\[crio.runtime.runtimes.crun\]\nruntime_path = \"\/usr\/bin\/crun\"\nruntime_type = \"oci\"\nruntime_root = \"\"/g' /etc/crio/crio.conf
# sudo sed -i 's/\[crio.network\]/\[crio.network\]\nnetwork_dir = \"\/etc\/cni\/net.d\/\"\nplugin_dir = \"\/opt\/cni\/bin\"/g' /etc/crio/crio.conf

sudo sed -i 's/\[crio.runtime\]/\# \[crio.runtime\]/g' /etc/crio/crio.conf
sudo sed -i 's/\[crio.network\]/\# \[crio.network\]/g' /etc/crio/crio.conf

echo -e "
[crio.runtime]
# Overide defaults to not use systemd cgroups.
conmon_cgroup = \"pod\"
cgroup_manager = \"systemd\"
default_runtime = \"crun\"

[crio.runtime.runtimes.crun]
runtime_path = \"/usr/bin/crun\"
runtime_type = \"oci\"
runtime_root = \"\"

[crio.network]
network_dir = \"/etc/cni/net.d/\"
plugin_dir = \"/opt/cni/bin\" "  | sudo tee -a /etc/crio/crio.conf

fi

        # crio bridge 設定檔
cat <<EOF | sudo tee /etc/cni/net.d/100-crio-bridge.conf > /dev/null 
{
    "cniVersion": "0.3.1",
    "name": "crio",
    "type": "bridge",
    "bridge": "cni0",
    "isGateway": true,
    "ipMasq": true,
    "hairpinMode": true,
    "ipam": {                                                                   
        "type": "host-local",
        "routes": [
            { "dst": "0.0.0.0/0" }
        ],
        "ranges": [
            [{ "subnet": "10.85.0.0/16" }]
        ]
    }
}
EOF

fi


# P4. kubelet kubeadm kubectl 
    echo "--- k8s套件下載中 ---" ; sleep 3
        k8s=/etc/kubernetes/manifests/kube-apiserver.yaml > /dev/null
    if  [ -f $k8s ] ; then
        echo "-- k8s install completed --" ; sleep 2
    else
        sudo apt-get -y update
        sudo apt-get -qy install apt-transport-https --yes
    # GPG key 
        sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
    # Add k8s repository
        sudo echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    # 更新 repository
        sudo apt-get -qy update
    # 使用相同版本 kube
        sudo apt-get -qy install -y kubelet=${KUBE_VER} kubeadm=${KUBE_VER}
    # 保持套件版本，避免發生問題
        sudo apt-mark hold kubelet kubeadm
    
    # kube-vip  yaml 檔下載設定
        #if [ "$hn" = "$master" ] ; then 
            #wget -O - https://raw.githubusercontent.com/kube-vip/kube-vip/main/docs/manifests/v0.4.1/kube-vip-arp.yaml | sed "s|eth0|${KUBE_INTERFACE}|g" | sed "s|192.168.0.1|${KUBE_VIP}|g" | sed "s|imagePullPolicy\: Always|imagePullPolicy\: IfNotPresent|g" | sudo tee /etc/kubernetes/manifests/kube-vip-arp.yaml
        #fi

    # helm
        curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
        sudo echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

        sudo apt-get -qy update
        sudo apt-get -qy install helm
        clear 
    fi
    
    # Start the cri-o & kubelet service
        echo "---cri-o & kubelet service 正在啟動---" ; sleep 3 
        sudo systemctl daemon-reload
        sudo systemctl enable --now crio
        sudo systemctl start crio
        sudo systemctl enable kubelet
    sleep 2
    clear

    # 重啟
    # sudo lsof -i -n -P|grep LISTEN
    # sudo kubeadm reset 
    # sudo systemctl start kubelet

# P5. 初始化 master 

    # ( CNI :calico 、 flannel 選擇)
    #calico default
    export POD_CIDR=10.85.0.0/16
    export SVC_CIDR=10.96.0.0/12

    #flannel default
    #POD_CIDR=10.244.0.0/16
    #SVC_CIDR=10.98.0.0/24

    # init master  
    if [[ $@ = "init" ]] ; then 
        sudo systemctl status crio | head -n 3 | awk 'NR==1; END{print}'
        sudo systemctl status kubelet | head -n 5 | awk 'NR==1; END{print}'
        read -p "init之前請檢查 crio & kubelet 是否正常運作"
            sudo kubeadm init --control-plane-endpoint=${master}:6443 --pod-network-cidr=${POD_CIDR} --service-cidr=${SVC_CIDR} --service-dns-domain=k8s.org --cri-socket=/var/run/crio/crio.sock --upload-certs --v=5
        # master 取得 kube 控制權
            mkdir -p ${HOME}/.kube ; sudo cp -i /etc/kubernetes/admin.conf ${HOME}/.kube/config; sudo chown $(id -u):$(id -g) ${HOME}/.kube/config
        # taint masternode (設定 Master 可以執行 Pod)
            kubectl taint node ${init_master} node-role.kubernetes.io/control-plane:NoSchedule-
            kubectl taint node ${init_master} node-role.kubernetes.io/master:NoSchedule-
    

# P6. calico (CNI)

    # calico yaml
    # https://raw.githubusercontent.com/projectcalico/calico/v3.24.0/manifests/calico.yaml

        #helm calico network
        helm repo add projectcalico https://projectcalico.docs.tigera.io/charts
        kubectl create namespace tigera-operator
        helm install calico projectcalico/tigera-operator --version v3.24.1 --namespace tigera-operator
        #watch kubectl get pods -n calico-system
        read -p "檢查初始化是否成功"  
        exit
    fi

# P7 . wokernode install

   for wlist in $nodes
    do
        if [[ $@ = "copy" ]] ; then
            clear
            echo "----$wlist scp now----" ; sleep 2
            scp k8s.sh $wlist:${HOME}

                ssh $wlist cat ${HOME}/k8s.sh > /dev/null
            if [ $? = 0 ] ; then
                 echo "Copy successfully" ; sleep 2
                        ssh $wlist ./k8s.sh
            fi
        fi
    done



# P8.  worker node join

    # join command
    export JOIN=$(echo " sudo `kubeadm token create --print-join-command 2>/dev/null`")

    for wlist in $nodes
    do
        if [[ $@ = "join" ]] ; then
            ssh $wlist $JOIN
            echo "---- $wlist join now ----" ; sleep 3

            # 標記為 worker 節點 
            kubectl label node ${wlist} node-role.kubernetes.io/worker=
            # 加入後需重啟 coredns掛掉，pod溝通
            kubectl -n kube-system rollout restart deployment coredns
            # kubectl -n kube-system rollout restert deployment calico-kube-controllers
        fi
    done

    clear 
        echo " podman & crio & kubernetes 套件及設定完成 " 
        echo " [ init | join | copy ]"  " (./k8s.sh init  or  ./k8s.sh join)"
        read -p "請先初始化(init) & (copy) 完成前兩項動作後,再將woker node (join)"







