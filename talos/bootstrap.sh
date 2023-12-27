#!/bin/bash

# set INITIAL_NODE knode01.home.macro.network
INITIAL_NODE=knode01.home.macro.network

doppler run -p talhelper -c main -- talhelper genconfig --no-gitignore

talosctl config merge ./clusterconfig/talosconfig

talosctl apply-config -i -n $INITIAL_NODE -f clusterconfig/home-$INITIAL_NODE.yaml
echo "Applied config to $INITIAL_NODE"

echo "Waiting..."
sleep 60

talosctl bootstrap -e $INITIAL_NODE -n $INITIAL_NODE
echo "Bootstrapped $INITIAL_NODE"

echo "Waiting..."
sleep 60

talosctl kubeconfig -e kube.home.macro.network -n kube.home.macro.network

echo "Waiting..."
sleep 20

kubectl kustomize extras/cilium/ --enable-helm | kubectl apply -f -
kubectl kustomize extras/kubelet-csr-approver/ --enable-helm | kubectl apply -f -

doppler run -p talhelper -c main envsubst < extras/doppler/secrets.yaml | kubectl apply -f -

kubectl certificate approve $(kubectl get csr --sort-by=.metadata.creationTimestamp | grep Pending | awk '{print $1}')

talosctl health -n $INITIAL_NODE

eval $(doppler run -p talhelper -c main -- talhelper gencommand apply --extra-flags "-i")

# kubectl kustomize extras/argocd/ --enable-helm | kubectl apply -f -
# kubectl kustomize extras/argocd-apps/ | kubectl apply -f -
