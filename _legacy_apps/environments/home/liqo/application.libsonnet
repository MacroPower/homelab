local app = import '../../../base/liqo/application.libsonnet';

app.withChartValues(|||
  apiServer:
    address: https://kube.home.macro.network:6443

  auth:
    config:
      addressOverride: liqo-auth.home.macro.network

  networkManager:
    config:
      # -- The subnet used by the pods in your cluster, in CIDR notation (e.g., 10.0.0.0/16).
      podCIDR: "10.128.0.0/14"
      # -- The subnet used by the services in you cluster, in CIDR notation (e.g., 172.16.0.0/16).
      serviceCIDR: "10.112.0.0/12"
      reservedSubnets:
        - 192.168.0.0/16
        - 172.16.0.0/12
        - 10.0.0.0/10
        - 10.64.0.0/11
        - 10.96.0.0/12

  gateway:
    service:
      type: "LoadBalancer"
      annotations:
        io.cilium/lb-ipam-ips: "10.10.30.3"
      labels:
        bgp.kubernetes.macro.network/peer_group: cbgp
    config:
      # Note: This is added to the *external* DNS server.
      addressOverride: liqo-gateway.home.macro.network

  discovery:
    config:
      # -- Specify an unique ID (must be a valid uuidv4) for your cluster, instead of letting helm generate it automatically at install time.
      # You can generate it using the command: `uuidgen`
      clusterIDOverride: "57fcb13c-e14d-4564-9cdf-1afc26da8035"
      clusterName: "home"
      clusterLabels:
        liqo.io/provider: talos
        liqo.io/remote-cluster-name: home
|||)
