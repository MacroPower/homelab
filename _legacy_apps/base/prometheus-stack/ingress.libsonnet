local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressSuffix = std.extVar('ingressSuffix');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='prometheus-ingress',
  namespace=ns.metadata.name,
  host='prometheus%s' % ingressSuffix,
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
) +
ingress.new(
  name='alertmanager-ingress',
  namespace=ns.metadata.name,
  host='alertmanager%s' % ingressSuffix,
  serviceName='alertmanager-operated',
  servicePort=9093,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Alertmanager',
    'gethomepage.dev/description': 'Alert Routing System',
    'gethomepage.dev/group': 'Observability',
    'gethomepage.dev/icon': 'si-prometheus',
    'gethomepage.dev/podSelector': '',
  },
)
