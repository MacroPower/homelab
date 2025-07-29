local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressSuffix = std.extVar('ingressSuffix');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='rook-ceph-dashboard',
  namespace=ns.metadata.name,
  host='ceph-dashboard%s' % ingressSuffix,
  serviceName='rook-ceph-mgr-dashboard',
  servicePort=7000,
  annotations=ingressAnnotations {
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Rook Ceph',
    'gethomepage.dev/description': 'Distributed File, Block & Object Storage',
    'gethomepage.dev/group': 'Cluster Management',
    'gethomepage.dev/icon': 'ceph',
    'gethomepage.dev/podSelector': '',
  },
)
