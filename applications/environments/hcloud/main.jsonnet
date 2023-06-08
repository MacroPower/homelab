local apps = [
  import 'argocd/application.libsonnet',
  import 'authentik-remote-cluster/application.libsonnet',
  import 'cert-manager/application.libsonnet',
  import 'crossplane/application.libsonnet',
  import 'descheduler/application.libsonnet',
  import 'external-dns/application.libsonnet',
  import 'external-secrets/application.libsonnet',
  import 'fip-controller/application.libsonnet',
  import 'goldilocks/application.libsonnet',
  import 'homepage/application.libsonnet',
  import 'inlets-server/application.libsonnet',
  import 'jaeger-operator/application.libsonnet',
  import 'k8s-event-logger/application.libsonnet',
  import 'linkerd/application.libsonnet',
  import 'linkerd-control-plane/application.libsonnet',
  import 'linkerd-multicluster/application.libsonnet',
  import 'linkerd-multicluster-home/application.libsonnet',
  import 'linkerd-viz/application.libsonnet',
  import 'metallb/application.libsonnet',
  import 'metrics-server/application.libsonnet',
  import 'openspeedtest/application.libsonnet',
  import 'opentelemetry-operator/application.libsonnet',
  import 'prometheus/application.libsonnet',
  import 'prometheus-stack/application.libsonnet',
  import 'rclone-restic/application.libsonnet',
  import 'traefik/application.libsonnet',
  import 'vpa/application.libsonnet',
];

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
