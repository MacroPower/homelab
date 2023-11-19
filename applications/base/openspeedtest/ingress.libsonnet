local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='openspeedtest-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='openspeedtest',
  servicePort=3000,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'OpenSpeedTest',
    'gethomepage.dev/description': 'Self-hosted HTML5 Network Speed Test',
    'gethomepage.dev/group': 'Apps',
    'gethomepage.dev/icon': 'openspeedtest',
    'gethomepage.dev/podSelector': '',
  },
)
