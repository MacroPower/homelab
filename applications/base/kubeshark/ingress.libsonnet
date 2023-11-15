local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='kubeshark-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='kubeshark-hub',
  servicePort=80,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Kubeshark',
    'gethomepage.dev/description': '',
    'gethomepage.dev/group': '',
    'gethomepage.dev/icon': '',
    'gethomepage.dev/podSelector': '',
  },
)
