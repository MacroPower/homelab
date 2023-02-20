apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ./namespaces
  - ./argocd
  - secrets.yaml
  - application-set.yaml
  - https://github.com/hetznercloud/hcloud-cloud-controller-manager/releases/download/${ccm_version}/ccm-networks.yaml

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

patchesStrategicMerge:
  - |-
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: hcloud-cloud-controller-manager
      namespace: kube-system
    spec:
      template:
        spec:
          containers:
            - name: hcloud-cloud-controller-manager
              command:
                - "/bin/hcloud-cloud-controller-manager"
                - "--cloud-provider=hcloud"
                - "--leader-elect=false"
                - "--allow-untagged-cloud"
                - "--allocate-node-cidrs=true"
                - "--cluster-cidr=${cluster_cidr_ipv4}"
