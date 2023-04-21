local cluster_credentials = import '../../../base/linkerd-multicluster-link/cluster_credentials.libsonnet';

[
  cluster_credentials.new('hcloud'),
]
+ std.parseYaml(importstr 'link.yaml')
