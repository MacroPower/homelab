local app = import '../../../base/traefik/application.libsonnet';

app.withBasePath('applications/environments/home/traefik').withChartParams({
  'tlsOptions.default.clientAuth': 'null',
  'service.annotations.metallb\\.universe\\.tf/loadBalancerIPs': '10.0.6.10',
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
  'tracing.openTelemetry.grpc': '{}',
  'tracing.openTelemetry.insecure': 'true',
}).withChartValues(|||
  env:
    - name: HOST_IP
      valueFrom:
        fieldRef:
          fieldPath: status.hostIP
    - name: TRAEFIK_TRACING_OPENTELEMETRY_ADDRESS
      value: "$(HOST_IP):4317"
|||)
