local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='{{ .Name }}-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='< REPLACE ME >',
  servicePort=80,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': '{{ .Name }}',
    'gethomepage.dev/description': '< REPLACE ME >',
    'gethomepage.dev/group': '< REPLACE ME >',
    'gethomepage.dev/icon': '< REPLACE ME >',
    'gethomepage.dev/podSelector': '',
  },
)
