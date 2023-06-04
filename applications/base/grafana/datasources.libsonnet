local ds_grafana_cloud = std.parseYaml(importstr 'datasources/grafana-cloud.yaml');
local ds_grafana_cloud_secrets = std.parseYaml(importstr 'datasources/grafana-cloud-secrets.yaml');
local ds_in_cluster = std.parseYaml(importstr 'datasources/in-cluster.yaml');

[
  ds_grafana_cloud,
  ds_grafana_cloud_secrets,
  ds_in_cluster,
]
