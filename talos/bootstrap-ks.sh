kubectl kustomize extras/cilium/ --enable-helm | kubectl apply -f -
kubectl kustomize extras/kubelet-csr-approver/ --enable-helm | kubectl apply -f -

doppler run -p talhelper -c main envsubst < extras/doppler/secrets.yaml | kubectl apply -f -

kubectl kustomize extras/argocd/ --enable-helm | kubectl apply -f -
kubectl kustomize extras/argocd-apps/ --enable-helm | kubectl apply -f -
