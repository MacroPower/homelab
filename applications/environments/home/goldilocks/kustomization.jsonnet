local app = import '../../../lib/app.libsonnet';
local resources = std.parseYaml(importstr '../../../base/goldilocks/application.yaml');

app.from(resources).withExtVars({
  ingressAnnotations: |||
    'kubernetes.io/ingress.class': 'traefik'
  |||,
  ingressHost: 'goldilocks.home.macro.network',
})
