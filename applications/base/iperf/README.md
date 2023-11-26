# iperf3

## Testing tailscale

```sh
## Expose the service to the cluster
##
echo "
apiVersion: v1
kind: Service
metadata:
  annotations:
    tailscale.com/tailnet-ip: 100.x.x.x
  name: iperf
  namespace: tailscale-operator
spec:
  externalName: example.com # overwritten by operator
  type: ExternalName
" | kubectl apply -f -

## Get a shell with iperf3
##
kubectl netshoot run tmp-shell

## Run iperf3 in client mode against the service
##
iperf3 -c iperf.tailscale-operator.svc -p 5201 -i 1 -t 10
```
