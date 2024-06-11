local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='owncloud',
  path='applications/base/owncloud',
  namespace=ns.metadata.name,
).withChart(
  name='ocis',
  repoURL='https://jacobcolvin.com/helm-charts',
  targetRevision='1.0.0',
  releaseName='ocis',
  values='values.yaml'
).withIgnoreDifferences([
  {
    group: '',
    kind: 'Secret',
    name: 'ldap-ca',
    jsonPointers: [
      '/data',
    ],
  },
  {
    group: '',
    kind: 'Secret',
    name: 'ldap-cert',
    jsonPointers: [
      '/data',
    ],
  },
  {
    group: '',
    kind: 'Secret',
    name: 'idp-secrets',
    jsonPointers: [
      '/data',
    ],
  },
])
