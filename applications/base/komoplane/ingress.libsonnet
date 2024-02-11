local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='komoplane-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='komoplane',
  servicePort=8090,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Komoplane',
    'gethomepage.dev/description': 'Crossplane resource visualizer',
    'gethomepage.dev/group': 'Apps',
    'gethomepage.dev/icon': 'mdi-pokeball',
    'gethomepage.dev/podSelector': '',
  },
)
