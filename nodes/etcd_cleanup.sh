# the script cleaning up on etcd node server

sudo systemctl stop etcd
sudo systemctl disable etcd

sudo rm /etc/etcd/ca.pem
sudo rm /etc/etcd/etcd-key.pem
sudo rm /etc/etcd/etcd.pem

sudo rm -rf /var/lib/etcd

sudo rm /usr/local/bin/etcd
sudo rm /usr/local/bin/etcdctl

sudo rm /etc/systemd/system/etcd.service

sudo systemctl daemon-reload
