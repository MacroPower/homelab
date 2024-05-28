local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='external-dns-adguard-1',
  path='applications/base/external-dns-adguard-1',
  namespace=ns.metadata.name,
).withChart(
  name='external-dns',
  repoURL='https://kubernetes-sigs.github.io/external-dns',
  targetRevision='1.14.4',
  releaseName='external-dns-adguard-1',
  values='../external-dns-adguard/values.yaml',
  skipCrds=true,
).withChartValues(|||
  provider:
    name: webhook
    webhook:
      env:
        - name: ADGUARD_HOME_URL
          value: "http://adguard-home-1.adguard-home.adguard-home.svc:3000/control/"
        - name: ADGUARD_HOME_USER
        - name: ADGUARD_HOME_PASS
|||)
