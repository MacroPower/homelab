local app = import '../../../base/traefik/application.libsonnet';

app.withBasePath('applications/environments/home/traefik').withChartParams({
  'tlsOptions.default.clientAuth': 'null',
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
}).withChartValues(|||
  image:
    tag: v3.0.0-beta4

  tracing:
    openTelemetry:
      address: main-collector.opentelemetry.svc:4317
      grpc: true
      insecure: true

  service:
    labels:
      bgp.kubernetes.macro.network/peer_group: cbgp
    ipFamilyPolicy: SingleStack

  env:
    - name: HOST_IP
      valueFrom:
        fieldRef:
          fieldPath: status.hostIP
    - name: TRAEFIK_TRACING_OPENTELEMETRY_ADDRESS
      value: "$(HOST_IP):4317"
|||)
