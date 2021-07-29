# Thanos

## Getting Started

First, apply `environments/default/` to create namespaces and minio.

Add a secret to configure object storage:

```bash
kubectl create secret generic thanos-objectstorage --from-file=thanos.yaml=thanos.yaml -n monitoring
```

See https://thanos.io/tip/thanos/storage.md/ for details.

And then apply:

```bash
tk apply environments/thanos/ --tla-str "apiServer=https://...:6443"
```
