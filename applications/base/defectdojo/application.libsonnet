local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='defectdojo',
  path='applications/base/defectdojo',
  namespace=ns.metadata.name,
).withChart(
  name='defectdojo',
  repoURL='https://raw.githubusercontent.com/DefectDojo/django-DefectDojo/helm-charts',
  targetRevision='1.6.125',
  releaseName='defectdojo',
  values='values.yaml'
).withChart(
  name='redis',
  repoURL='https://charts.bitnami.com/bitnami',
  targetRevision='19.1.5',
  releaseName='defectdojo-redis',
  values='values-redis.yaml'
)
