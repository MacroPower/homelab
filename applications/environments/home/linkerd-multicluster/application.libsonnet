local app = import '../../../base/linkerd-multicluster/application.libsonnet';

app.withChartParams({
  'gateway.serviceAnnotations.metallb\\.universe\\.tf/loadBalancerIPs': '10.0.6.2',
})
