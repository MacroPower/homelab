local app = import '../../../base/traefik/application.libsonnet';

app.withBasePath('applications/environments/home/traefik').withChartParams({
  'tlsOptions.default.clientAuth': 'null',
  'service.annotations.metallb\\.universe\\.tf/loadBalancerIPs': '10.0.6.1',
})
