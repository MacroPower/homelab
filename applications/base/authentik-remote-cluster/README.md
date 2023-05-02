# Authentik Remote Cluster

Pending automation.

## Add outpost integration

Navigate to System / Outpost Integrations.

Click Create.

Select Kubernetes Service-Connection.

For kubeconfig, generate the config using the `authentik-remote-cluster` service
account.

## Add outpost

Navigate to Applications / Outposts.

Click Create.

Select the integration created above.

Select the remote application (macro.network).

Add the following config:

```yaml
log_level: debug
docker_labels: null
authentik_host: https://authentik.macro.network/
docker_network: null
container_image: null
docker_map_ports: true
kubernetes_replicas: 1
kubernetes_namespace: authentik
authentik_host_browser: ""
object_naming_template: ak-outpost
authentik_host_insecure: false
kubernetes_service_type: ClusterIP
kubernetes_image_pull_secrets: []
kubernetes_ingress_class_name: null
kubernetes_disabled_components: []
kubernetes_ingress_annotations:
  traefik.ingress.kubernetes.io/router.entrypoints: websecure
  external-dns.alpha.kubernetes.io/cloudflare-proxied: "true"
  traefik.ingress.kubernetes.io/router.middlewares: "authentik-ak-outpost-l5d-header-middleware@kubernetescrd"
kubernetes_ingress_secret_name: ""
```
