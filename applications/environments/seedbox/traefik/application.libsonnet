local app = import '../../../base/traefik/application.libsonnet';

app.withBasePath('applications/environments/seedbox/traefik').withChartValues(|||
  service:
    additionalServices:
      internal:
        spec:
          clusterIP: 10.43.0.20
|||)
