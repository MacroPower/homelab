local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='transmission-webdav-ingress',
  namespace=ns.metadata.name,
  host=ingressHost,
  serviceName='transmission-webdav-sftpgo',
  servicePort=81,
  tlsSecretName='transmission-webdav-cert',
  annotations=ingressAnnotations {
    'cert-manager.io/issuer': 'letsencrypt-prod',
    'external-dns.alpha.kubernetes.io/cloudflare-proxied': 'false',
    'traefik.ingress.kubernetes.io/router.tls.options': 'traefik-no-client-auth@kubernetescrd',
    'gethomepage.dev/enabled': 'true',
    'gethomepage.dev/name': 'Transmission WebDAV',
    'gethomepage.dev/description': 'WebDAV Server for Transmission Data',
    'gethomepage.dev/group': 'Media',
    'gethomepage.dev/icon': 'files',
    'gethomepage.dev/podSelector': '',
  },
)
