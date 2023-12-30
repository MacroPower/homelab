local app = import '../../../base/traefik/application.libsonnet';

app.withBasePath('applications/environments/nas01/traefik').withChartParams({
  'tlsOptions.default.clientAuth': 'null',
}).withChartValues(|||
  image:
    tag: v3.0.0-beta4

  tracing:
    openTelemetry:
      address: main-collector.opentelemetry.svc:4317
      grpc: true
      insecure: true

  env:
    - name: HOST_IP
      valueFrom:
        fieldRef:
          fieldPath: status.hostIP
    - name: TRAEFIK_TRACING_OPENTELEMETRY_ADDRESS
      value: "$(HOST_IP):4317"
|||)
