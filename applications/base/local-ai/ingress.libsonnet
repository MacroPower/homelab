local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='local-ai-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='local-ai',
  servicePort=80,
  annotations=ingressAnnotations {
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'LocalAI',
    'gethomepage.dev/description': 'Self-hosted LLMs and more',
    'gethomepage.dev/external': 'true',
    'gethomepage.dev/group': 'Apps',
    'gethomepage.dev/icon': 'si-openai',
    'gethomepage.dev/podSelector': '',
  },
)
