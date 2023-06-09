local app = import '../../lib/app.libsonnet';

app.new(
  name='external-dns',
  path='applications/base/external-dns-cloudflare',
  namespace='kube-system',
).withChart(
  name='external-dns',
  repoURL='https://kubernetes-sigs.github.io/external-dns',
  targetRevision='1.13.0',
  releaseName='external-dns',
  values='values.yaml'
)
