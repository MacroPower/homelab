local app = import '../../../lib/app.libsonnet';

app.new(
  name='coredns',
  path='applications/environments/home/coredns',
  namespace='kube-system',
)
