local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressSuffix = std.extVar('ingressSuffix');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='liqo-auth-ingress',
  namespace=ns.metadata.name,
  host='liqo-auth%s' % ingressSuffix,
  serviceName='liqo-auth',
  servicePort=443,
  annotations=ingressAnnotations,
)
