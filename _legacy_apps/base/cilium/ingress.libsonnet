local ingress = import '../../lib/ingress.libsonnet';

local ingressSuffix = std.extVar('ingressSuffix');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='hubble-ingress',
  namespace='cilium',
  host='hubble%s' % ingressSuffix,
  serviceName='hubble-ui',
  servicePort=80,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Hubble',
    'gethomepage.dev/description': 'Network, Service & Security Observability',
    'gethomepage.dev/group': 'Observability',
    'gethomepage.dev/icon': 'cilium',
    'gethomepage.dev/podSelector': '',
  },
)
