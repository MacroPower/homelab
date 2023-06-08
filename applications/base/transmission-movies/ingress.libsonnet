local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressSuffix = std.extVar('ingressSuffix');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='flood-movies-ingress',
  namespace=ns.metadata.name,
  host='flood-movies%s' % ingressSuffix,
  serviceName='transmission-movies-flood',
  servicePort=3001,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Flood - Movies',
    'gethomepage.dev/description': 'Transmission Web UI',
    'gethomepage.dev/group': 'Media',
    'gethomepage.dev/icon': 'flood',
    'gethomepage.dev/podSelector': '',
  },
)
