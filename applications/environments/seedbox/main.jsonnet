local apps = [
  import 'argocd/application.libsonnet',
  import 'authentik-remote-cluster/application.libsonnet',
  import 'cert-manager/application.libsonnet',
  import 'crossplane/application.libsonnet',
  import 'descheduler/application.libsonnet',
  import 'external-dns/application.libsonnet',
  import 'external-secrets/application.libsonnet',
  import 'homepage/application.libsonnet',
  import 'inlets-server/application.libsonnet',
  import 'jaeger-operator/application.libsonnet',
  import 'k8s-event-logger/application.libsonnet',
  import 'k8up/application.libsonnet',
  import 'local-volume-static-provisioner/application.libsonnet',
  import 'metrics-server/application.libsonnet',
  import 'openspeedtest/application.libsonnet',
  import 'opentelemetry-operator/application.libsonnet',
  import 'prometheus/application.libsonnet',
  import 'prometheus-stack/application.libsonnet',
  import 'rclone-restic/application.libsonnet',
  import 'traefik/application.libsonnet',
  import 'transmission/application.libsonnet',
  import 'transmission-anime/application.libsonnet',
  import 'transmission-movies/application.libsonnet',
  import 'transmission-music/application.libsonnet',
  import 'transmission-tv/application.libsonnet',
  import 'transmission-webdav/application.libsonnet',
];

[
  app
  .withAppNamespace('argocd')
  .withDestinationServer('https://kubernetes.default.svc')
  .withExtVars({
    ingressHost: '%s-sb.macro.network' % app.metadata.name,
    ingressSuffix: '-sb.macro.network',
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
