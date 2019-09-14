# CNI plugin Weave-Net

# Ubuntu 16.04
sudo ln -s /run/resolvconf/ /run/systemd/resolve

# weave-plugin-2.5.2
# $ kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

kubectl apply -f deployments/weave/net.yml
