local cluster_credentials = import '../../../base/linkerd-multicluster-link/cluster_credentials.libsonnet';

[
  cluster_credentials.new('seedbox'),
]
+ std.parseYaml(importstr 'link.yaml')
