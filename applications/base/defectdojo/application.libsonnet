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
  targetRevision='18.6.1',
  releaseName='defectdojo-redis',
  values='values-redis.yaml'
).withChart(
  name='kubernetes-python',
  repoURL='https://jacobcolvin.com/helm-charts/',
  targetRevision='0.1.1',
  releaseName='defectdojo-post-install',
  values='values-post-install.yaml'
)
