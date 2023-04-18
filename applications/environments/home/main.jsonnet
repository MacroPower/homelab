local apps = [
  import 'fluent-bit/main.jsonnet',
  import 'goldilocks/main.jsonnet',
];

[
  app
  .withAppNamespace('argocd')
  .withDestinationServer('https://kubernetes.default.svc')
  .withExtVars({
    ingressHost: '%s.home.macro.network' % app.metadata.name,
    ingressAnnotations: |||
      'traefik.ingress.kubernetes.io/router.entrypoints': 'websecure'
    |||,
  })
  .withBase(
    repoURL='https://github.com/MacroPower/homelab',
    targetRevision='argo-apps'
  )
  for app in apps
]
