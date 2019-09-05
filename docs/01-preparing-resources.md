# Preparation

Kubernetes Network Design

|Network         |CIDR             |
|----------------|-----------------|
|Infra Network   |`172.18.30.1/24` |
|Pod Network     |`10.244.0.0/16`  |
|Service Network |`10.32.0.0/24`   |

## VMs

|IP Address      |VM Hostname         |
|----------------|--------------------|
|172.18.30.50    |`mini-k8s-data`     |
|172.18.30.51    |`mini-k8s-master`   |
|172.18.30.52    |`mini-k8s-worker-1` |

## Provisioning CA and Generating TLS Certificates

Follow [kubernetes-the-hard-way-bare-metal](https://github.com/oahcran/kubernetes-the-hard-way-bare-metal/blob/master/docs/02-provisioning-certs-config-encryption.md) guide. The difference is to generate additional `etcd` cert and key for k8s Master and Data node communications.

## Distributing Files

This is the summary for files generated and where should be distributed to, either, Data, Master or Worker instances.

**Data**

```
ca.pem
etcd.pem
etcd-key.pem
```

Copy the appropriate files:

```
for instance in mini-k8s-data; do
  scp ca.pem etcd-key.pem etcd.pem ubuntu@${instance}:~/
done
```

**Master**

```
ca.pem
ca-key.pem
kubernetes-key.pem
kubernetes.pem
service-account-key.pem
service-account.pem
admin.kubeconfig
kube-controller-manager.kubeconfig
kube-scheduler.kubeconfig
encryption-config.yaml
etcd.pem
etcd-key.pem
```

Copy the appropriate files:

```
for instance in mini-k8s-master; do
  scp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem \
    etcd-key.pem etcd.pem \
    admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig \
    encryption-config.yaml ubuntu@${instance}:~/
done
```

**Worker**

```
ca.pem
${instance}-key.pem
${instance}.pem
${instance}.kubeconfig
kube-proxy.kubeconfig
```

Copy the appropriate files:

```
for instance in mini-k8s-worker-1; do
  scp ca.pem ${instance}-key.pem ${instance}.pem \
      ${instance}.kubeconfig kube-proxy.kubeconfig ubuntu@${instance}:~/
done
```
