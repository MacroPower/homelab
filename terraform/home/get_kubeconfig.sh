terraform output -raw kubeconfig > kubeconfig.yaml

KUBECONFIG=kubeconfig.yaml:~/.kube/config kubectl config view --flatten > ~/.kube/config
