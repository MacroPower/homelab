local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='linkerd-dashboard-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='web',
  servicePort=8084,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Linkerd Viz',
    'gethomepage.dev/description': 'Service Mesh Dashboard',
    'gethomepage.dev/group': 'Observability',
    'gethomepage.dev/icon': 'https://cncf-branding.netlify.app/img/projects/linkerd/icon/color/linkerd-icon-color.png',
    'gethomepage.dev/podSelector': '',
  },
)
