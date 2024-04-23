local app = import '../../../base/traefik/application.libsonnet';

app.withBasePath('applications/environments/home/traefik').withChartValues(|||
  ports:
    pfsensesyslog:
      expose:
        default: true
      port: 5140
      exposedPort: 5140
      protocol: UDP
    taloskernel:
      expose:
        default: true
      port: 6050
      exposedPort: 6050
      protocol: UDP
    talossystem:
      expose:
        default: true
      port: 6051
      exposedPort: 6051
      protocol: UDP

  service:
    labels:
      bgp.kubernetes.macro.network/peer_group: cbgp
    ipFamilyPolicy: RequireDualStack
|||)
