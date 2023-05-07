local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='traefik-dashboard-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='traefik-dashboard',
  servicePort=9000,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Traefik',
    'gethomepage.dev/description': 'Ingress Controller',
    'gethomepage.dev/group': 'Cluster Management',
    'gethomepage.dev/icon': 'traefik',
    'gethomepage.dev/href': 'https://%s/dashboard/' % ingressHost,
    'gethomepage.dev/podSelector': '',
  },
) + [
  {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: 'traefik-dashboard',
    },
    spec: {
      type: 'ClusterIP',
      selector: {
        'app.kubernetes.io/name': 'traefik',
        'app.kubernetes.io/instance': 'traefik-traefik',
      },
      ports: [{
        name: 'traefik',
        protocol: 'TCP',
        port: 9000,
        targetPort: 'traefik',
      }],
    },
  },
]
