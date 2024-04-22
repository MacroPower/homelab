local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='argo-workflows-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='argo-workflows-server',
  servicePort=2746,
  annotations=ingressAnnotations {
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Argo Workflows',
    'gethomepage.dev/description': 'Cloud-native Workflow Engine',
    'gethomepage.dev/group': 'Apps',
    'gethomepage.dev/icon': 'argocd',
    'gethomepage.dev/podSelector': '',
  },
)
