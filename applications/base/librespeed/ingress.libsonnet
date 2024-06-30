local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='librespeed-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='librespeed',
  servicePort=80,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'librespeed',
    'gethomepage.dev/description': 'Network Speed Test',
    'gethomepage.dev/group': 'Apps',
    'gethomepage.dev/icon': 'librespeed',
    'gethomepage.dev/podSelector': '',
  },
)
