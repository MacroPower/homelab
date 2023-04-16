local app = import '../../lib/app.libsonnet';

local resources = [
  import 'goldilocks/kustomization.jsonnet',
];

[
  if resource.kind == 'Application'
  then app.from(resource)
       .withRepo(targetRevision='argo-apps')
       .withDestinationServer('https://kubernetes.default.svc')
       .withNamespace('argocd')
  else resource
  for resource in resources
]
