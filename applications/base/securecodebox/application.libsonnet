local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='securecodebox',
  path='applications/base/securecodebox',
  namespace=ns.metadata.name,
).withChart(
  name='operator',
  repoURL='https://charts.securecodebox.io/',
  targetRevision='4.6.0',
  releaseName='securecodebox',
  values='values.yaml'
)
