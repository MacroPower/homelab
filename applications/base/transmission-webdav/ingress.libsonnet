local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='transmission-webdav-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='transmission-webdav',
  servicePort=50000,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'transmission-webdav-auth@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Transmission WebDAV',
    'gethomepage.dev/description': 'WebDAV Server for Transmission Data',
    'gethomepage.dev/group': 'Media',
    'gethomepage.dev/icon': 'files',
    'gethomepage.dev/podSelector': '',
  },
)
