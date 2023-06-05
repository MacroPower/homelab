local ingress = import '../../lib/ingress.libsonnet';
local ns = import '../transmission/namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='transmission-webdav-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='transmission-webdav-rclone',
  servicePort=50000,
  tlsSecretName='transmission-webdav-cert',
  annotations=ingressAnnotations {
    'cert-manager.io/issuer': 'letsencrypt-prod',
    'external-dns.alpha.kubernetes.io/cloudflare-proxied': 'false',
    'traefik.ingress.kubernetes.io/router.middlewares': 'transmission-webdav-auth@kubernetescrd',
    'traefik.ingress.kubernetes.io/router.tls.options': 'traefik-no-client-auth@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Transmission WebDAV',
    'gethomepage.dev/description': 'WebDAV Server for Transmission Data',
    'gethomepage.dev/group': 'Media',
    'gethomepage.dev/icon': 'https://simpleicons.org/icons/saturn.svg',
    'gethomepage.dev/podSelector': '',
  },
)
