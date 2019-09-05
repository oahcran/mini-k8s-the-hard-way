# CNI plugin Flannel

# Ubuntu 16.04
sudo ln -s /run/resolvconf/ /run/systemd/resolve

# flannel v0.11.0
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml
