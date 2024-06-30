local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='defectdojo-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='defectdojo-django',
  servicePort=80,
  annotations=ingressAnnotations {
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'DefectDojo',
    'gethomepage.dev/description': 'DevSecOps, ASPM & Vulnerability Management',
    'gethomepage.dev/group': 'Cluster Management',
    'gethomepage.dev/icon': 'si-owasp',
    'gethomepage.dev/podSelector': '',
  },
)
