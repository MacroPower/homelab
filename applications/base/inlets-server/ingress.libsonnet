local ingress = import '../../lib/ingress.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='inlets-ingress',
  host='linkerd-tunnel.macro.network',
  serviceName='linkerd-tunnel',
  servicePort=8123,
  tlsSecretName='linkerd-tunnel-cert',
  annotations=ingressAnnotations {
    'cert-manager.io/issuer': 'letsencrypt-prod',
    'external-dns.alpha.kubernetes.io/cloudflare-proxied': 'false',
    'traefik.ingress.kubernetes.io/router.tls.options': 'traefik-no-client-auth@kubernetescrd',
  },
)
