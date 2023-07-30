#!/bin/bash

doppler run -p talhelper -c main talhelper genconfig

talosctl --talosconfig=./clusterconfig/talosconfig config endpoint https://kube.home.macro.network:6443
talosctl config merge ./clusterconfig/talosconfig

talosctl apply-config -i -n knode01.home.macro.network -f clusterconfig/home-knode01.home.macro.network.yaml

echo "Waiting..."
sleep 60

talosctl bootstrap -e kube.home.macro.network -n knode01.home.macro.network

echo "Waiting..."
sleep 60

talosctl kubeconfig -e kube.home.macro.network -n knode01.home.macro.network

echo "Waiting..."
sleep 20

kubectl kustomize extras/cillium/ --enable-helm | kubectl apply -f -
kubectl kustomize extras/kubelet-csr-approver/ --enable-helm | kubectl apply -f -
kubectl kustomize extras/argo-cd/ --enable-helm | kubectl apply -f -

doppler run -p talhelper -c main envsubst < extras/doppler/secrets.yaml | kubectl apply -f -

kubectl certificate approve $(kubectl get csr --sort-by=.metadata.creationTimestamp | grep Pending | awk '{print $1}')
