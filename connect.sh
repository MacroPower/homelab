#!/bin/bash

MASTER_NODE_USER=root
MASTER_NODE_HOST=$1
MASTER_NODE_PORT=$2

K8S_API=https://$MASTER_NODE_HOST:6443
CLUSTER=hcloud

###################

echo "Checking SSH connection to $MASTER_NODE_HOST"
if ! ssh -q -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=5 -p $MASTER_NODE_PORT $MASTER_NODE_USER@$MASTER_NODE_HOST exit; then
    echo
    echo "Can't connect... please check your ssh key and config"
    echo
    exit 1
fi

sshrun() {
    ssh -q -o StrictHostKeyChecking=no -p $MASTER_NODE_PORT $MASTER_NODE_USER@$MASTER_NODE_HOST -- $@
}

while ! sshrun 'kubectl cluster-info'; do
    echo "Waiting cluster"
    sleep 2
done

rawconfig="$(sshrun kubectl config view -ojson --raw)"

cacert_file=$(mktemp)
cert_file=$(mktemp)
key_file=$(mktemp)

echo "$rawconfig" | jq -r '.clusters[0].cluster["certificate-authority-data"]' | base64 -d >$cacert_file
echo "$rawconfig" | jq -r '.users[0].user["client-certificate-data"]' | base64 -d >$cert_file
echo "$rawconfig" | jq -r '.users[0].user["client-key-data"]' | base64 -d >$key_file

# create cluster entry in local kubectl config
kubectl config set-cluster $CLUSTER \
    --server=$K8S_API \
    --certificate-authority=$cacert_file \
    --embed-certs=true

kubectl config set-credentials $CLUSTER \
    --client-certificate=$cert_file \
    --client-key=$key_file \
    --embed-certs=true

rm -f $cacert_file $cert_file $key_file

kubectl config set-context $CLUSTER \
    --cluster=$CLUSTER \
    --user=$CLUSTER

kubectl config use-context $CLUSTER

kubectl config view -ojson --raw > .kubeconfig
