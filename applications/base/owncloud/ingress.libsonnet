local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='owncloud-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='ocis',
  servicePort=80,
  annotations=ingressAnnotations {
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'ownCloud',
    'gethomepage.dev/description': 'File Storage and Collaboration',
    'gethomepage.dev/group': 'Apps',
    'gethomepage.dev/icon': 'owncloud',
    'gethomepage.dev/podSelector': '',
  },
)
