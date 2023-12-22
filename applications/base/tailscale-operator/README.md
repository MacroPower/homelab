# tailscale-operator

## Generating new credentials

Each unique instance of tailscale-operator requires:

- TAILSCALE_OPERATOR_CLIENT_ID (client_id)
- TAILSCALE_OPERATOR_CLIENT_SECRET (client_secret)

To generate these:

1. Settings -> Tailnet Settings -> OAuth clients -> Generate OAuth client
2. Add description "k8s-<cluster-name>"
3. Grant Devices Read & Write
4. Add "tag:k8s-operator"
5. Click "Generate client"

See https://tailscale.com/kb/1236/kubernetes-operator/#deploying-the-operator-using-a-helm-chart
