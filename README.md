# k8s install for ubuntu 22.04 、 ubuntu 20.04 

version ssh

# 環境設定 , 安裝Kubernetes 設定固定IP前置作業
0. wget https://raw.githubusercontent.com/ragrag6326/ragrag6326/main/env-setting.sh -O env.sh
1. wget https://raw.githubusercontent.com/ragrag6326/ragrag6326/main/key.sh 
2. 請先設定好一台m1 執行(上面網址) , 執行(key.sh)放入puttygen產生的公鑰,步驟 1 可做可不做 
3. m1設定完成後，再複製兩台 w1 w2 一樣執行env-setting.Sh 設定 IP 

# k8s.sh 自動部屬 cri-o podman kubelet kubeadm 套件
  0. wget https://raw.githubusercontent.com/ragrag6326/k8s/main/k8s.sh 
  1. m1 ./k8s.sh 安裝完成後 :輸入 " k8s.sh copy " 讓套件部屬在 w1 w2上
  2. 複製w1 w2且安裝完成後 m1 輸入 : " k8s.sh init " 
     出現等字樣後 :sudo kubeadm join m1:6443 --token "..."  --discovery-token-ca-cert-hash sha256: "..."
  3. 在將 w1 w2 加入叢集  " k8s.sh join " 


# 2023/07/09 新增安裝Kubernetes 1.27.0 版
wget https://raw.githubusercontent.com/ragrag6326/k8s-ubuntu/main/k8s-1.27.sh -O k8s.sh ; chmod +x k8s.sh
