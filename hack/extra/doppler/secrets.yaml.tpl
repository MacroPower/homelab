apiVersion: v1
kind: Secret
metadata:
  name: doppler-credentials
  namespace: kube-system
type: Opaque
stringData:
  token: ${doppler_token}
