local app = import '../../lib/app.libsonnet';

app.new(
  name='kube-prometheus-stack',
  path='applications/base/kube-prometheus-stack',
  namespace='prometheus',
).withExtVars({})
