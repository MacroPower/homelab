local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='rook-ceph-operator',
  path='applications/base/rook-ceph-operator',
  namespace=ns.metadata.name,
).withChart(
  name='rook-ceph',
  repoURL='https://charts.rook.io/release',
  targetRevision='v1.15.2',
  releaseName='rook-ceph',
  values='values.yaml'
)
