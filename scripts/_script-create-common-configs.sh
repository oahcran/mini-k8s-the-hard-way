#!/bin/bash
set -e

export KUBERNETES_ETCD_IP_ADDRESS=172.18.30.50

# use domain for external
export KUBERNETES_MASTER_EXTERNAL_DOMAIN=mini-k8s.home.cloudylab.net

export KUBERNETES_MASTER_INTERNAL_IP_ADDRESS=172.18.30.51

# Service Cluster IP Address
export KUBERNETES_SERVICE_INTERNAL_ADDRESS=10.32.0.1

## Certificate Authority
cfssl gencert -initca configs/ca-csr.json | cfssljson -bare ca

### The Kubernetes Data etcd Certificate
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=configs/ca-config.json \
  -hostname=${KUBERNETES_ETCD_IP_ADDRESS},127.0.0.1 \
  -profile=kubernetes \
  configs/etcd-csr.json | cfssljson -bare etcd

### The Kubernetes API Server Certificate
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=configs/ca-config.json \
  -hostname=${KUBERNETES_SERVICE_INTERNAL_ADDRESS},${KUBERNETES_MASTER_INTERNAL_IP_ADDRESS},${KUBERNETES_MASTER_EXTERNAL_DOMAIN},127.0.0.1,kubernetes.default \
  -profile=kubernetes \
  configs/kubernetes-csr.json | cfssljson -bare kubernetes

### The Admin Client Certificate
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=configs/ca-config.json \
  -profile=kubernetes \
  configs/admin-csr.json | cfssljson -bare admin

### kube-proxy

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=configs/ca-config.json \
  -profile=kubernetes \
  configs/kube-proxy-csr.json | cfssljson -bare kube-proxy

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=configs/ca-config.json \
  -profile=kubernetes \
  configs/kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=configs/ca-config.json \
  -profile=kubernetes \
  configs/kube-scheduler-csr.json | cfssljson -bare kube-scheduler

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=configs/ca-config.json \
  -profile=kubernetes \
  configs/service-account-csr.json | cfssljson -bare service-account

## kube-proxy.kubeconfig
kubectl config set-cluster k8s-the-hard-way-metal \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_MASTER_INTERNAL_IP_ADDRESS}:6443 \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
  --client-certificate=kube-proxy.pem \
  --client-key=kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=k8s-the-hard-way-metal \
  --user=system:kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

## kube-controller-manager.kubeconfig
kubectl config set-cluster k8s-the-hard-way-metal \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=kube-controller-manager.pem \
  --client-key=kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context default \
  --cluster=k8s-the-hard-way-metal \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig

## kube-scheduler.kubeconfig
kubectl config set-cluster k8s-the-hard-way-metal \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=kube-scheduler.pem \
  --client-key=kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-context default \
  --cluster=k8s-the-hard-way-metal \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig

## admin.kubeconfig
kubectl config set-cluster k8s-the-hard-way-metal \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=admin.kubeconfig

kubectl config set-credentials admin \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem \
  --embed-certs=true \
  --kubeconfig=admin.kubeconfig

kubectl config set-context default \
  --cluster=k8s-the-hard-way-metal \
  --user=admin \
  --kubeconfig=admin.kubeconfig

kubectl config use-context default --kubeconfig=admin.kubeconfig

## ENCRYPTION_KEY
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

## Validating DNS
openssl x509 -in kubernetes.pem -text | grep "DNS:"
openssl x509 -in etcd.pem -text | grep "IP Address:"
