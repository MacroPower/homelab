local app = import '../../../base/traefik/application.libsonnet';

app.withBasePath('applications/environments/seedbox/traefik').withChartValues(|||
  service:
    type: ClusterIP
|||)
