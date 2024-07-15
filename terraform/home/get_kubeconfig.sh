terraform output -raw kubeconfig > kubeconfig.yaml

cp ~/.kube/config ~/.kube/config.bak
KUBECONFIG=~/.kube/config.bak:kubeconfig.yaml kubectl config view --flatten > ~/.kube/config
