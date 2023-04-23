apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ./namespaces
  - ./argocd
  - secrets.yaml
  - apps.yaml

patches:
  - target:
      version: v1
      kind: Secret
      name: doppler-credentials
    patch: |-
      - op: add
        path: /data
        value:
          token: ${doppler_token_b64}
