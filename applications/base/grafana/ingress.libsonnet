local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='grafana-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='grafana-service',
  servicePort=3000,
  tailnetIngress=true,
  annotations=ingressAnnotations {
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Grafana',
    'gethomepage.dev/description': 'Visualization Platform',
    'gethomepage.dev/group': 'Observability',
    'gethomepage.dev/icon': 'grafana',
    'gethomepage.dev/podSelector': '',
    'gethomepage.dev/ping': 'http://grafana-service.grafana.svc:3000/api/health',
  },
)
