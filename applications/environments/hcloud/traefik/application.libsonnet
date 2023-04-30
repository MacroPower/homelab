local app = import '../../../base/traefik/application.libsonnet';

app.withChartParams({
  'service.annotations.metallb\\.universe\\.tf/allow-shared-ip': 'main',
})
