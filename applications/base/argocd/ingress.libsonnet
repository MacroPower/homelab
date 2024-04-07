local ingress = import '../../lib/ingress.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='argocd-ingress',
  namespace='argocd',
  host=ingressHost,
  serviceName='argocd-server',
  servicePort=80,
  annotations=ingressAnnotations {
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Argo CD',
    'gethomepage.dev/description': 'GitOps',
    'gethomepage.dev/group': 'Cluster Management',
    'gethomepage.dev/icon': 'argocd',
    'gethomepage.dev/podSelector': '',
  },
)
