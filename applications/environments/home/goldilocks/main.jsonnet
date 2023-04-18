local app = import '../../../base/goldilocks/application.libsonnet';

app.withExtVars({
  ingressAnnotations: |||
    'kubernetes.io/ingress.class': 'traefik'
  |||,
  ingressHost: 'goldilocks.home.macro.network',
})
