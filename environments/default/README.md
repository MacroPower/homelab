# Default ENV

The default environment contains all prerequisite resources that _must_ be deployed before other environments.

For example, the default environment contains namespaces for all other environments.

## Getting Started

Add a secret to configure minio:

```
kubectl create secret generic minio-key \
  --from-literal=minio-access-key='MyAccessKey' \
  --from-literal=minio-secret-key='MySecretKey'
```

And then apply:

```bash
tk apply environments/default/ --tla-str "apiServer=https://...:6443"
```
