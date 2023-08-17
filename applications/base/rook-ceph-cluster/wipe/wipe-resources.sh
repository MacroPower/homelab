kubectl patch app rook-ceph-cluster -n argocd -p '{"metadata": {"finalizers": ["resources-finalizer.argocd.argoproj.io"]}}' --type merge --type merge
kubectl delete app rook-ceph-cluster -n argocd

kubectl patch app rook-ceph-operator -n argocd -p '{"metadata": {"finalizers": ["resources-finalizer.argocd.argoproj.io"]}}' --type merge --type merge
kubectl delete app rook-ceph-operator -n argocd

kubectl patch CephBlockPool ceph-blockpool -n rook-ceph -p '{"metadata":{"finalizers":null}}' --type=merge
kubectl patch CephFileSystem ceph-filesystem -n rook-ceph -p '{"metadata":{"finalizers":null}}' --type=merge
kubectl patch CephObjectStore ceph-objectstore -n rook-ceph -p '{"metadata":{"finalizers":null}}' --type=merge
