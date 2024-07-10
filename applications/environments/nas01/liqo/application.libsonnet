local app = import '../../../base/liqo/application.libsonnet';

app.withChartValues(|||
  apiServer:
    address: https://nas01.home.macro.network:6443

  auth:
    config:
      addressOverride: liqo-auth.nas01.home.macro.network

  networkManager:
    config:
      # -- The subnet used by the pods in your cluster, in CIDR notation (e.g., 10.0.0.0/16).
      podCIDR: "10.132.0.0/16"
      # -- The subnet used by the services in you cluster, in CIDR notation (e.g., 172.16.0.0/16).
      serviceCIDR: "10.133.0.0/16"
      reservedSubnets:
        - 192.168.0.0/16
        - 172.16.0.0/12
        - 10.0.0.0/10
        - 10.64.0.0/11
        - 10.96.0.0/12

  gateway:
    # No more than one replica can be scheduled on a given node.
    replicas: 1
    service:
      type: "NodePort"
    nodePort:
      port: 5871
    config:
      addressOverride: nas01.home.macro.network
      listeningPort: 5871

  discovery:
    config:
      # -- Specify an unique ID (must be a valid uuidv4) for your cluster, instead of letting helm generate it automatically at install time.
      # You can generate it using the command: `uuidgen`
      clusterIDOverride: "b0c99edf-61e3-464c-a1f9-50d3f02e2585"
      clusterName: "nas01"
      clusterLabels:
        liqo.io/provider: k3s
        liqo.io/remote-cluster-name: nas01
|||)
