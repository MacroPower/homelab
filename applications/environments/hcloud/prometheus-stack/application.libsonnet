local app = import '../../../base/prometheus-stack/application.libsonnet';

app.withChartParams({
  'prometheus.prometheusSpec.retention': '2h',
  'prometheus.prometheusSpec.resources.requests.cpu': '500m',
  'prometheus.prometheusSpec.resources.requests.memory': '2Gi',
  'prometheus.prometheusSpec.resources.limits.cpu': '500m',
  'prometheus.prometheusSpec.resources.limits.memory': '2Gi',
})
