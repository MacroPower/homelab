local app = import '../../lib/app.libsonnet';

app.new(
  name='csi-addons',
  path='applications/base/csi-addons',
  namespace='csi-addons-system',
)
