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

./bootstrap-ks.sh

kubectl certificate approve $(kubectl get csr --sort-by=.metadata.creationTimestamp | grep Pending | awk '{print $1}')

talosctl health -n $INITIAL_NODE

./apply.sh
