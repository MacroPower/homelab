local apps = [
  import 'goldilocks/main.jsonnet',
];

[
  app
  .withAppNamespace('argocd')
  .withDestinationServer('https://kubernetes.default.svc')
  .withBase(
    repoURL='https://github.com/MacroPower/homelab',
    targetRevision='argo-apps'
  )
  for app in apps
]
