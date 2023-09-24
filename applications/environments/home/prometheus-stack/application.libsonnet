local app = import '../../../base/prometheus-stack/application.libsonnet';

app.withChartParams({
  'prometheus.prometheusSpec.retention': '30d',
  'prometheus.prometheusSpec.retentionSize': '180GB',
  'prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName': 'ceph-filesystem',
  'prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]': 'ReadWriteOnce',
  'prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage': '200Gi',
})
