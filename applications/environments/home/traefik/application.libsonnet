local app = import '../../../base/traefik/application.libsonnet';

app.withBasePath('applications/environments/home/traefik').withChartParams({
  'tlsOptions.default.clientAuth': 'null',
  'service.annotations.metallb\\.universe\\.tf/loadBalancerIPs': '10.0.6.1',
  'ports.pfsensesyslog.expose': 'true',
  'ports.pfsensesyslog.port': '5140',
  'ports.pfsensesyslog.exposedPort': '5140',
  'ports.pfsensesyslog.protocol': 'UDP',
  'ports.taloskernel.expose': 'true',
  'ports.taloskernel.port': '6050',
  'ports.taloskernel.exposedPort': '6050',
  'ports.taloskernel.protocol': 'UDP',
  'ports.talossystem.expose': 'true',
  'ports.talossystem.port': '6051',
  'ports.talossystem.exposedPort': '6051',
  'ports.talossystem.protocol': 'UDP',
})
