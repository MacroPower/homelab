local app = import '../../../lib/app.libsonnet';

app.new(
  name='fip-controller',
  path='applications/environments/hcloud/fip-controller',
  namespace='fip-controller',
)
