# k8s install for ubuntu 22.04

# ubEnv-setting.Sh  安裝Kubernetes設定IP前置作業
1. 請先執行三台VM虛擬機 ubEnv-setting.Sh 個別執行設定好 m1 w1 w2
2. 或是設定好一台m1再複製兩台 w1 w2 執行ubEnv-setting.Sh 設定 IP

# k8s.sh 自動部屬 cri-o podman kubelet kubeadm 套件
  1. m1 安裝完成後 :輸入 " k8s.sh copy " 讓套件部屬在 w1 w2上
  2. 複製w1 w2且安裝完成後 m1 輸入 : " k8s.sh init " 最後出現等字樣後
      sudo kubeadm join m1:6443 --token "..."  --discovery-token-ca-cert-hash sha256: "..."
  3. 最後在將 w1 w2 加入叢集  " k8s.sh join " 


