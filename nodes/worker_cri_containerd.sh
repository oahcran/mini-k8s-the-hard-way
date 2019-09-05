# the script running on worker node server

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

sudo sysctl net.ipv4.ip_forward
#net.ipv4.ip_forward = 1
sudo sysctl net.bridge.bridge-nf-call-iptables
#net.bridge.bridge-nf-call-iptables = 1

sudo apt-get update && sudo apt-get install -y apt-transport-https \
  ca-certificates socat conntrack ipset libseccomp2

wget https://storage.googleapis.com/cri-containerd-release/cri-containerd-1.2.8.linux-amd64.tar.gz

sudo tar --no-overwrite-dir -C / -xzf cri-containerd-1.2.8.linux-amd64.tar.gz

## remove GCE related configs
sudo rm -r /opt/containerd/cluster

sudo mkdir -p /etc/containerd

sudo containerd config default > config.toml
sudo mv config.toml /etc/containerd/config.toml

sudo systemctl daemon-reload
sudo systemctl enable containerd
sudo systemctl start containerd

# kubelet kube-proxy cni-plugins
wget -q --show-progress --https-only --timestamping \
    https://github.com/containernetworking/plugins/releases/download/v0.7.6/cni-plugins-amd64-v0.7.6.tgz \
    https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl \
    https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-proxy \
    https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubelet

sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes \
  /etc/kubernetes/manifests

chmod +x kubectl kube-proxy kubelet
sudo mv kubectl kube-proxy kubelet /usr/local/bin/
sudo tar -xvf cni-plugins-amd64-v0.7.6.tgz -C /opt/cni/bin/

# configure kubelet
sudo mv ${HOSTNAME}-key.pem ${HOSTNAME}.pem /var/lib/kubelet/
sudo mv ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubeconfig
sudo mv ca.pem /var/lib/kubernetes/

cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
address: 0.0.0.0
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
cgroupDriver: cgroupfs
cgroupsPerQOS: true
clusterDNS:
  - "10.32.0.10"
podCIDR: "10.244.0.0/16"
clusterDomain: "cluster.local"
resolvConf: "/run/systemd/resolve/resolv.conf"
rotateCertificates: true
tlsCertFile: "/var/lib/kubelet/${HOSTNAME}.pem"
tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME}-key.pem"
contentType: application/vnd.kubernetes.protobuf
cpuCFSQuota: true
enableControllerAttachDetach: true
enableDebuggingHandlers: true
enforceNodeAllocatable:
  - "pods"
failSwapOn: false
hairpinMode: promiscuous-bridge
healthzBindAddress: 127.0.0.1
healthzPort: 10248
port: 10250
serializeImagePulls: true
staticPodPath: /etc/kubernetes/manifests
EOF

cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --pod-cidr="10.244.0.0/16" \\
  --cni-bin-dir=/opt/cni/bin \\
  --cni-conf-dir=/etc/cni/net.d \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --network-plugin=cni \\
  --register-node=true \\
  --container-runtime=remote \\
  --runtime-request-timeout=15m \\
  --container-runtime-endpoint=unix:///run/containerd/containerd.sock \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# configure kube-proxy
sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig

cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
bindAddress: 0.0.0.0
clientConnection:
  acceptContentTypes: ""
  contentType: application/vnd.kubernetes.protobuf
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
clusterCIDR: 10.244.0.0/16
mode: "iptables"
metricsBindAddress: 127.0.0.1:10249
EOF

cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# reload and start kubelet and kube-proxy
sudo systemctl daemon-reload
sudo systemctl enable kubelet kube-proxy
sudo systemctl start kubelet kube-proxy
