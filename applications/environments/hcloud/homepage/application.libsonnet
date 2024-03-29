local app = import '../../../base/homepage/application.libsonnet';

app.withChartParams({
  'config.widgets[1].greeting.text': 'HCloud',
  'config.settings.background.image': 'https://images.unsplash.com/photo-1502790671504-542ad42d5189?auto=format&fit=crop&w=2560&q=80',
}).withExtVarsMixin({
  ingressAnnotations: |||
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd'
    'traefik.ingress.kubernetes.io/router.entrypoints': 'websecure'
    'external-dns.alpha.kubernetes.io/cloudflare-proxied': 'true'
  |||,
})
