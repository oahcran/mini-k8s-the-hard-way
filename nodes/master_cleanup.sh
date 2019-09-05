# the script running on master node server

sudo systemctl stop kube-apiserver kube-controller-manager kube-scheduler
sudo systemctl disable kube-apiserver kube-controller-manager kube-scheduler

sudo rm /usr/local/bin/kubectl
sudo rm /usr/local/bin/kube-apiserver
sudo rm /usr/local/bin/kube-controller-manager
sudo rm /usr/local/bin/kube-scheduler

sudo rm /etc/systemd/system/kube-apiserver.service
sudo rm /etc/systemd/system/kube-controller-manager.service
sudo rm /etc/systemd/system/kube-scheduler.service

sudo rm /var/lib/kubernetes/kube-controller-manager.kubeconfig
sudo rm /var/lib/kubernetes/kube-scheduler.kubeconfig

sudo rm /etc/kubernetes/config/kube-scheduler.yaml

sudo rm -r /var/lib/kubernetes/
sudo rm -r /etc/kubernetes/config

sudo systemctl daemon-reload
