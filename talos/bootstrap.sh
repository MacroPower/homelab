#!/bin/bash

doppler run -p talhelper -c main -- talhelper genconfig --no-gitignore
talosctl --talosconfig=./clusterconfig/talosconfig config endpoint \
    knode01.home.macro.network \
    knode02.home.macro.network \
    knode03.home.macro.network

INITIAL_NODE=knode01.home.macro.network

talosctl apply-config --talosconfig=./clusterconfig/talosconfig \
    -i -e $INITIAL_NODE -n $INITIAL_NODE -f clusterconfig/home-$INITIAL_NODE.yaml

echo "Waiting..."
sleep 60

talosctl bootstrap --talosconfig=./clusterconfig/talosconfig \
    -e $INITIAL_NODE -n $INITIAL_NODE

echo "Waiting..."
sleep 60

talosctl config merge ./clusterconfig/talosconfig

talosctl kubeconfig

echo "Waiting..."
sleep 20

kubectl kustomize extras/cilium/ --enable-helm | kubectl apply -f -
kubectl kustomize extras/kubelet-csr-approver/ --enable-helm | kubectl apply -f -

doppler run -p talhelper -c main envsubst < extras/doppler/secrets.yaml | kubectl apply -f -

kubectl certificate approve $(kubectl get csr --sort-by=.metadata.creationTimestamp | grep Pending | awk '{print $1}')

# kubectl kustomize extras/argocd/ --enable-helm | kubectl apply -f -
# kubectl kustomize extras/argocd-apps/ | kubectl apply -f -
