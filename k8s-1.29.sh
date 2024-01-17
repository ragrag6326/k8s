#!/bin/bash

echo "  crio & kubernetes 1.27套件及設定安裝 " 
echo " [ instll | init | copy | join ]"  " (./k8s.sh init  or  ./k8s.sh join)"
echo "master node 請先安裝(install) & 初始化(init) 完成前兩項動作後 , (copy) 再將 woker node (join)"
echo " (copy)前 , 先確認n1 n2 有放master node的 pub key "

    # 環境宣告
    sudo apt install net-tools -y
    # cri & k8s 版本宣告
    
    export KUBE_VER=1.29.0
    export CRIO_VERSION=1.25
    export OS_VERSION_ID=xUbuntu_$(cat /etc/os-release | grep VERSION_ID | awk -F"=" '{print $2}' | tr -d '"')

    # Network
    export NIC=`ifconfig | grep 'flags' | cut -d ':' -f 1  | grep 'en'`
    export IP=`ip a | grep "$NIC" | grep 'inet' | awk '{ print $2 }' | cut -d '.' -f 1-3`
    export GW=`route -n | grep "$NIC" | tr -s ' ' | cut -d ' ' -f 2 | head -n 1`
    export NM=`ip a | grep inet | grep "$NIC" | awk '{ print $2 }' | cut -d '/' -f 2` 

    # node & service
    export master=$(cat /etc/hosts | grep -v "#" | grep "$IP" | awk '{ print $2 }' | grep "m" )
    export nodes=$(cat /etc/hosts | grep -v "#" | grep "$IP" | awk '{ print $2 }' | grep "n" )
    export init_master=$(echo ${master} | awk '{ print $1 }')
    export hn=`sudo cat /etc/hostname` 

# --------------------------------------------------------------------------------------------------------
    # <-- copy kubenetes install file to nodes -->

    # 安裝 kubenetes
if [[ $@ = "install" ]] ; then

    sudo apt-get update
    sudo apt-get upgrade -y

    # P1. 系統設定
    # 2-1. 關閉 swap 
    sudo swapoff -a

    #註解 swap 內容
    sudo cat /etc/fstab | grep "#/swap" > /dev/null
    if [ $? != 0 ] ; then
        sudo sed -i 's|/swap.img|#/swap.img|g' /etc/fstab
        echo "----swap off successed----" ; sleep 3
    #確認是否關閉
        sudo swapon --show 
    else
        echo "----swap has been off---- " ; sleep 3
    fi
        clear 

    # 2-2. bridge 
    sudo ls /proc/sys/net/bridge/ > /dev/null
    if [ $? = 0 ] ; then
        echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
    else
        modprobe br_netfilter
        echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
    fi

    # 2-3. ipv4 轉發
        echo 1 > /proc/sys/net/ipv4/ip_forward


    # P2. 添加存儲庫

    # Container Engine ( CRIO )
    echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS_VERSION_ID/ /"|sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
    echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$OS_VERSION_ID/ /"|sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.list

    curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION/$OS_VERSION_ID/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
    curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS_VERSION_ID/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add

    # Add Kubernetes repository:
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

    # P3. 更新軟件包索引並安裝 Cri-o

    sudo apt-get update
    sudo apt-get install cri-o cri-o-runc cri-tools -y

    # 啟用並啟動 Cri-o
    sudo systemctl daemon-reload
    sudo systemctl enable crio --now


    # P4. kubelet kubeadm kubectl 

    echo "--- k8s套件下載中 ---" ; sleep 3
        k8s=/etc/kubernetes/manifests/kube-apiserver.yaml > /dev/null
    if  [ -f $k8s ] ; then
        echo "-- k8s install completed --" ; sleep 2
    else
        # 更新 repository
        sudo apt-get -qy update
        # 使用相同版本 kube
        sudo apt-get install -y kubeadm=1.28.2-00 kubelet=1.28.2-00 kubectl=1.28.2-00
        # 保持套件版本，避免發生問題
        sudo apt-mark hold kubelet kubeadm kubectl
    fi

        # kubectl 1.29版
        # curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.29.0/bin/linux/amd64/kubectl
        # chmod +x kubectl
        # sudo mv kubectl /usr/bin/kubelet
        


        # Start the cri-o & kubelet service
        echo "---cri-o & kubelet service 正在啟動---" ; sleep 3 
        sudo systemctl daemon-reload
        sudo systemctl enable --now crio
        sudo systemctl start crio
        sudo systemctl enable kubelet
        sleep 2
fi



# --------------------------------------------------------------------------------------------------------
    # <-- copy kubenetes install file to nodes -->

    # init master  
    if [[ $@ = "init" ]] ; then
            
        # ( CNI :calico 、 flannel 選擇)
        #calico default
        export POD_CIDR=10.85.0.0/16
        export SVC_CIDR=10.96.0.0/12

        #flannel default
        #POD_CIDR=10.244.0.0/16
        #SVC_CIDR=10.98.0.0/24

        echo -e "$(systemctl status crio | head -n 3 | awk 'NR==1; END{print}' | sed -E 's/(active \(running\))/\\e[32m\1\\e[0m/' |sed -E 's/^(●)/\\e[32m\1\\e[0m/' )"
        echo -e "$(systemctl status kubelet | head -n 5 | awk 'NR==1; END{print}' | sed -E 's/(active \(running\))/\\e[32m\1\\e[0m/' |sed -E 's/^(●)/\\e[32m\1\\e[0m/' )"

        read -p "init之前請檢查 crio & kubelet 是否正常運作"
            sudo kubeadm init --pod-network-cidr=${POD_CIDR} --service-cidr=${SVC_CIDR} --kubernetes-version ${KUBE_VER}
            # master 取得 kube 控制權
            mkdir -p ${HOME}/.kube ; sudo cp -i /etc/kubernetes/admin.conf ${HOME}/.kube/config; sudo chown $(id -u):$(id -g) ${HOME}/.kube/config
            # taint masternode (設定 Master 可以執行 Pod)
            kubectl taint node ${init_master} node-role.kubernetes.io/control-plane:NoSchedule-
            kubectl taint node ${init_master} node-role.kubernetes.io/master:NoSchedule-
            sleep 5

        # 縮寫指令
        cp ~/.bashrc ~/.bashrcbak
        echo -e "
            alias kg='kubectl get'
            alias ka='kubectl apply'
            alias kd='kubectl describe'
            alias kdel='kubectl delete'" >>  ~/.bashrc

        # 指令重新執行生效    
        . ~/.bashrc

        # <-- calico ( CNI安裝 ) -->  init 階段完成安裝
        # calico yaml ( https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises ) 
        kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml 
    fi

# --------------------------------------------------------------------------------------------------------
    # <-- copy kubenetes install file to nodes -->

   for wlist in $nodes
    do
        if [[ $@ = "copy" ]] ; then
            clear
            echo "----$wlist scp now----" ; sleep 2
            scp k8s.sh $wlist:${HOME}

            ssh $wlist cat ${HOME}/k8s.sh > /dev/null
            if [ $? = 0 ] ; then
                 echo "Copy successfully" ; sleep 2
                        ssh $wlist ./k8s.sh install
            fi
        fi
    done

# --------------------------------------------------------------------------------------------------------
    # <-- kubenetes node join -->
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
            read -p "join 完成"
        fi
    done


