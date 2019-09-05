#!/bin/bash
set -e

export KUBERNETES_MASTER_INTERNAL_IP_ADDRESS=172.18.30.51

#export KUBERNETES_NODE_NAME=mini-k8s-master
#export KUBERNETES_NODE_IP=172.18.30.51

export KUBERNETES_NODE_NAME=mini-k8s-worker-1
export KUBERNETES_NODE_IP=172.18.30.52

for instance in ${KUBERNETES_NODE_NAME}; do
cat > ${instance}-csr.json <<EOF
{
  "CN": "system:node:${instance}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Dallas",
      "O": "system:nodes",
      "OU": "Mini Kubernetes a Hard Way",
      "ST": "Texas"
    }
  ]
}
EOF
done

cfssl gencert \
  -ca=generated/ca.pem \
  -ca-key=generated/ca-key.pem \
  -config=configs/ca-config.json \
  -hostname=${KUBERNETES_NODE_NAME},${KUBERNETES_NODE_IP} \
  -profile=kubernetes \
  ${KUBERNETES_NODE_NAME}-csr.json | cfssljson -bare ${KUBERNETES_NODE_NAME}

openssl x509 -in ${KUBERNETES_NODE_NAME}.pem -text | grep "DNS:"

##

for instance in ${KUBERNETES_NODE_NAME}; do
  kubectl config set-cluster k8s-the-hard-way-metal \
    --certificate-authority=generated/ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_MASTER_INTERNAL_IP_ADDRESS}:6443 \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=${instance}.pem \
    --client-key=${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=k8s-the-hard-way-metal \
    --user=system:node:${instance} \
    --kubeconfig=${instance}.kubeconfig

  kubectl config use-context default --kubeconfig=${instance}.kubeconfig
done

## Clean Up
#for instance in ${KUBERNETES_NODE_NAME} ${MASTER_2_NAME} ${MASTER_3_NAME}; do
#  rm ${instance}*csr.json
#done
