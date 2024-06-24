terraform output -raw kubeconfig > kubeconfig.yaml

cp ~/.kube/config ~/.kube/config.bak
KUBECONFIG=kubeconfig.yaml:~/.kube/config kubectl config view --flatten > ~/.kube/config
