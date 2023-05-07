local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='authentik-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='authentik-home',
  servicePort=80,
  annotations=ingressAnnotations {
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Authentik',
    'gethomepage.dev/description': 'Identity Provider',
    'gethomepage.dev/group': 'Cluster Management',
    'gethomepage.dev/icon': 'authentik',
    'gethomepage.dev/podSelector': '',
  },
)
