local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='policy-reporter-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='policy-reporter-ui',
  servicePort=8080,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Policy Reporter',
    'gethomepage.dev/description': 'Interface and Notifications for Policy Reports',
    'gethomepage.dev/group': 'Cluster Management',
    'gethomepage.dev/icon': 'mdi-police-badge-outline',
    'gethomepage.dev/podSelector': '',
  },
)
