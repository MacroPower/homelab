local app = import '../../../base/linkerd-multicluster/application.libsonnet';

app.withChartParams({
  'gateway.serviceType': 'ClusterIP',
})
