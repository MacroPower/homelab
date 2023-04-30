apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ./namespaces
  - ./argocd
  - secrets.yaml
  - ccm-networks.yaml
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
              env:
                - name: "HCLOUD_LOAD_BALANCERS_ENABLED"
                  value: "false"
