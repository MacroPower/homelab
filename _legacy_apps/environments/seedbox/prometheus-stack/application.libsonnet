local app = import '../../../base/prometheus-stack/application.libsonnet';

app.withChartParams({
  'prometheus.prometheusSpec.retention': '2h',
  'prometheus.prometheusSpec.resources.requests.cpu': '250m',
  'prometheus.prometheusSpec.resources.requests.memory': '4Gi',
  'prometheus.prometheusSpec.resources.limits.memory': '4Gi',
})
