# mini Kubernetes cluster from a hard way

An experimental mini Kubernetes cluster:

* separate data (`etcd`) and master (`kube-apiserver`) to run at different instance.
* populate multi endpoints for `kube-apiserver`
    * localhost endpoint to interact with `kube-controller-manager` and `kube-scheduler`
    * internal endpoint communication with worker nodes `kubelet`
    * external endpoint by `kubectl`
* `containerd` runtime
* explore CNI plugins with [_Network Policy_](https://kubernetes.io/docs/concepts/services-networking/network-policies/) support

## details

* Kubernetes `v1.15.3`
* etcd `v3.3.15`
* containerd `1.2.8`
* CNI `v0.7.6`
    * Flannel `0.11.0`
    * Weave Net `2.5.2`
* CoreDNS `v1.5.0`
* Ubuntu `16.04.6 LTS`

## steps

* [Preparation](docs/01-preparing-resources.md)
* [Bootstrapping the Data `etcd` Node](docs/02-bootstrapping-etcd.md)
* [Bootstrapping the Control Plane](docs/03-bootstrapping-k8s-controllers.md)
* Bootstrapping the Worker Nodes
    * [runtime `containerd`](docs/04-bootstrapping-k8s-workers-containerd.md)
* Deploying CNI Networking Plugin
    * [`flannel`](docs/05-deploying-cni-network-plugin-flannel.md)
    * [`weave net`](docs/05-deploying-cni-network-plugin-weave.md)
* [Deploying the DNS Cluster Add-on](docs/06-dns-addon.md)

## output

```
NAME                STATUS   ROLES    AGE     VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
mini-k8s-worker-1   Ready    <none>   3m35s   v1.15.3   172.18.30.52   <none>        Ubuntu 16.04.6 LTS   4.4.0-161-generic   containerd://1.2.8
```
