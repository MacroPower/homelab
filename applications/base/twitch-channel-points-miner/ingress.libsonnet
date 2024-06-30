local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='twitch-channel-points-miner-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='twitch-channel-points-miner',
  servicePort=5000,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Twitch Channel Points Miner',
    'gethomepage.dev/description': 'Automated Boints Collector & Gamba Participant',
    'gethomepage.dev/group': 'Apps',
    'gethomepage.dev/icon': 'twitch',
    'gethomepage.dev/podSelector': '',
  },
)
