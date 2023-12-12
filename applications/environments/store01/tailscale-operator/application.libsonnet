local app = import '../../../base/tailscale-operator/application.libsonnet';

app.withChartParams({
  'operatorConfig.hostname': 'tailscale-operator-store01.home.macro.network',
})
