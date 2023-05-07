local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

local ingressHostDomain = std.join('.', std.split(ingressHost, '.')[1:]);

ingress.new(
  name='prometheus-ingress',
  namespace=ns.metadata.name,
  host='prometheus.%s' % ingressHostDomain,
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
  host='alertmanager.%s' % ingressHostDomain,
  serviceName='alertmanager-operated',
  servicePort=9093,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Alertmanager',
    'gethomepage.dev/description': 'Alert Routing System',
    'gethomepage.dev/group': 'Observability',
    'gethomepage.dev/icon': 'https://cncf-branding.netlify.app/img/projects/prometheus/icon/white/prometheus-icon-white.svg',
    'gethomepage.dev/podSelector': '',
  },
)
