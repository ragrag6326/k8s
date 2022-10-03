# k8s install for ubuntu 22.04

hosts 設定為 
m1:130
w1:132
w2:133

# ubEnv-setting.Sh  安裝Kubernetes設定IP前置作業
0. curl -L https://raw.githubusercontent.com/ragrag6326/k8s/main/ubEnv-setting.Sh | sh
1. 請先設定好一台m1 執行(上面網址)
2. m1設定完成後，再複製兩台 w1 w2 一樣執行ubEnv-setting.Sh 設定 IP 

# k8s.sh 自動部屬 cri-o podman kubelet kubeadm 套件
  0. wget https://raw.githubusercontent.com/ragrag6326/k8s/main/k8s.sh 
  1. m1 ./k8s.sh 安裝完成後 :輸入 " k8s.sh copy " 讓套件部屬在 w1 w2上
  2. 複製w1 w2且安裝完成後 m1 輸入 : " k8s.sh init " 
     出現等字樣後 :sudo kubeadm join m1:6443 --token "..."  --discovery-token-ca-cert-hash sha256: "..."
  3. 在將 w1 w2 加入叢集  " k8s.sh join " 


