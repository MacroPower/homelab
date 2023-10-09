local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='adguard-home-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='adguard-home',
  servicePort=3000,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'AdGuard Home',
    'gethomepage.dev/description': 'Ad-blocking DNS server',
    'gethomepage.dev/group': 'Apps',
    'gethomepage.dev/icon': 'adguard-home',
    'gethomepage.dev/podSelector': '',
  },
)
