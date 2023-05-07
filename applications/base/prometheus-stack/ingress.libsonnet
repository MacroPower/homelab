local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='prometheus-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='prometheus-operated',
  servicePort=9090,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Prometheus',
    'gethomepage.dev/description': 'Monitoring System & TSDB',
    'gethomepage.dev/group': 'Observability',
    'gethomepage.dev/icon': 'prometheus',
    'gethomepage.dev/podSelector': '',
  },
)
