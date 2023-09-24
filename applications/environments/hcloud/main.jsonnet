local apps = import 'imports.libsonnet';

[
  app
  .withAppNamespace('argocd')
  .withDestinationServer('https://kubernetes.default.svc')
  .withExtVars({
    ingressHost: '%s.macro.network' % app.metadata.name,
    ingressSuffix: '.macro.network',
    ingressAnnotations: |||
      'traefik.ingress.kubernetes.io/router.entrypoints': 'websecure'
      'external-dns.alpha.kubernetes.io/cloudflare-proxied': 'true'
    |||,
  })
  .withBase(
    repoURL='https://github.com/MacroPower/homelab',
    targetRevision='main',
  )
  for app in apps
]
