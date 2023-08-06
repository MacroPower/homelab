local apps = [
  import 'argocd/application.libsonnet',
  import 'authentik/application.libsonnet',
  import 'cert-manager/application.libsonnet',
  import 'crossplane/application.libsonnet',
  import 'coredns/application.libsonnet',
  import 'descheduler/application.libsonnet',
  import 'external-dns/application.libsonnet',
  import 'external-secrets/application.libsonnet',
  import 'external-services/application.libsonnet',
  import 'goldilocks/application.libsonnet',
  import 'grafana/application.libsonnet',
  import 'homepage/application.libsonnet',
  import 'inlets-client/application.libsonnet',
  import 'inlets-client-hcloud/application.libsonnet',
  import 'inlets-client-seedbox/application.libsonnet',
  import 'jaeger-aio/application.libsonnet',
  import 'jaeger-operator/application.libsonnet',
  import 'k8s-event-logger/application.libsonnet',
  import 'k8up/application.libsonnet',
  import 'metallb/application.libsonnet',
  import 'metrics-server/application.libsonnet',
  import 'openspeedtest/application.libsonnet',
  import 'opentelemetry-operator/application.libsonnet',
  import 'pgadmin/application.libsonnet',
  import 'prometheus/application.libsonnet',
  import 'prometheus-stack/application.libsonnet',
  import 'rclone-restic/application.libsonnet',
  import 'robusta/application.libsonnet',
  import 'traefik/application.libsonnet',
  import 'vpa/application.libsonnet',
];

[
  app
  .withAppNamespace('argocd')
  .withDestinationServer('https://kubernetes.default.svc')
  .withExtVars({
    ingressHost: '%s.home.macro.network' % app.metadata.name,
    ingressSuffix: '.home.macro.network',
    ingressAnnotations: |||
      'traefik.ingress.kubernetes.io/router.entrypoints': 'websecure'
    |||,
  })
  .withBase(
    repoURL='https://github.com/MacroPower/homelab',
    targetRevision='main',
  )
  for app in apps
]
