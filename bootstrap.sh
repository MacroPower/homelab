kubectl --kubeconfig .kubeconfig apply -k applications/bootstrap

echo "Sleeping so that bootstrapping has time to complete..."

sleep 30

kubectl --kubeconfig .kubeconfig apply -f applications/overlays/hcloud/appset.yaml
