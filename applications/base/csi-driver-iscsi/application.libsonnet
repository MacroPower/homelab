local app = import '../../lib/app.libsonnet';

app.new(
  name='csi-driver-iscsi',
  path='applications/base/csi-driver-iscsi',
  namespace='kube-system',
)
