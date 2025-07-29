local app = import '../../../lib/app.libsonnet';

app.new(
  name='coredns',
  path='applications/environments/nas01/coredns',
  namespace='kube-system',
)
