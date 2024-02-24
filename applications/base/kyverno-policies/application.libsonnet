local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='kyverno-policies',
  path='applications/base/kyverno-policies',
  namespace=ns.metadata.name,
  annotations={
    'argocd.argoproj.io/hook': 'PreSync',
  },
  renderer='kustomize',
)
