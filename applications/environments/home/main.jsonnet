local apps = [
  import 'argocd/main.jsonnet',
  import 'authentik/main.jsonnet',
  import 'cert-manager/main.jsonnet',
  import 'crossplane/main.jsonnet',
  import 'coredns/application.jsonnet',
  import 'descheduler/main.jsonnet',
  import 'external-secrets/main.jsonnet',
  import 'fluent-bit/main.jsonnet',
  import 'goldilocks/main.jsonnet',
  import 'grafana/main.jsonnet',
  import 'inlets-client/main.jsonnet',
  import 'jaeger-operator/main.jsonnet',
  import 'k8s-event-logger/main.jsonnet',
  import 'k8up/main.jsonnet',
  import 'kube-prometheus-stack/main.jsonnet',
  import 'linkerd/main.jsonnet',
  import 'linkerd-control-plane/main.jsonnet',
  import 'linkerd-multicluster/main.jsonnet',
  import 'linkerd-multicluster-hcloud/application.jsonnet',
  import 'linkerd-viz/main.jsonnet',
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
