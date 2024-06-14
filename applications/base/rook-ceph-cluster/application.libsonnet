local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='rook-ceph-cluster',
  path='applications/base/rook-ceph-cluster',
  namespace=ns.metadata.name,
).withChart(
  name='rook-ceph-cluster',
  repoURL='https://charts.rook.io/release',
  targetRevision='v1.14.6',
  releaseName='rook-ceph-cluster',
  values='values.yaml'
)
