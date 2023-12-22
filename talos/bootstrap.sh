#!/bin/bash

doppler run -p talhelper -c main talhelper genconfig

talosctl --talosconfig=./clusterconfig/talosconfig config endpoint https://kube.home.macro.network:6443
talosctl config merge ./clusterconfig/talosconfig

INITIAL_NODE=knode02.home.macro.network

talosctl apply-config -i -n $INITIAL_NODE -f clusterconfig/home-$INITIAL_NODE.yaml

echo "Waiting..."
sleep 60

talosctl bootstrap -e kube.home.macro.network -n $INITIAL_NODE

echo "Waiting..."
sleep 60

talosctl kubeconfig -e kube.home.macro.network -n kube.home.macro.network

echo "Waiting..."
sleep 20

kubectl kustomize extras/cilium/ --enable-helm | kubectl apply -f -
kubectl kustomize extras/kubelet-csr-approver/ --enable-helm | kubectl apply -f -

doppler run -p talhelper -c main envsubst < extras/doppler/secrets.yaml | kubectl apply -f -

kubectl certificate approve $(kubectl get csr --sort-by=.metadata.creationTimestamp | grep Pending | awk '{print $1}')

# kubectl kustomize extras/argocd/ --enable-helm | kubectl apply -f -
# kubectl kustomize extras/argocd-apps/ | kubectl apply -f -
