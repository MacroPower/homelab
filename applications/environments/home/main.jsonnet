local apps = [
  import 'argocd/application.libsonnet',
  import 'authentik/application.libsonnet',
  import 'cert-manager/application.libsonnet',
  import 'crossplane/application.libsonnet',
  import 'coredns/application.libsonnet',
  import 'descheduler/application.libsonnet',
  import 'external-dns/application.libsonnet',
  import 'external-secrets/application.libsonnet',
  import 'goldilocks/application.libsonnet',
  import 'grafana/application.libsonnet',
  import 'inlets-client/application.libsonnet',
  import 'jaeger-aio/application.libsonnet',
  import 'jaeger-operator/application.libsonnet',
  import 'k8s-event-logger/application.libsonnet',
  import 'k8up/application.libsonnet',
  import 'linkerd/application.libsonnet',
  import 'linkerd-control-plane/application.libsonnet',
  import 'linkerd-multicluster/application.libsonnet',
  import 'linkerd-multicluster-hcloud/application.libsonnet',
  import 'linkerd-viz/application.libsonnet',
  import 'metallb/application.libsonnet',
  import 'metrics-server/application.libsonnet',
  import 'openspeedtest/application.libsonnet',
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
