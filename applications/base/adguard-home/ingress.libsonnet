local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressSuffix = std.extVar('ingressSuffix');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='adguard-home-ingress',
  namespace=ns.metadata.name,
  host='adguard%s' % ingressSuffix,
  serviceName='adguard-home',
  servicePort=3000,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'AdGuard Home',
    'gethomepage.dev/description': 'Ad-blocking DNS Server',
    'gethomepage.dev/group': 'Apps',
    'gethomepage.dev/icon': 'adguard-home',
    'gethomepage.dev/podSelector': '',
  },
) +
ingress.new(
  name='dns-ingress',
  namespace=ns.metadata.name,
  host='dns%s' % ingressSuffix,
  serviceName='adguard-home',
  servicePort=3000,
  tlsSecretName='dns-cert',
  httpIngressPath='/dns-query',
  annotations=ingressAnnotations,
)
