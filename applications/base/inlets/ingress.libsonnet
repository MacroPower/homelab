local ingress = import '../../lib/ingress.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='inlets-ingress',
  host=ingressHost,
  serviceName='grafana',
  servicePort=80,
  annotations=ingressAnnotations {
    'cert-manager.io/issuer': 'letsencrypt-prod',
  },
)

//
//    'external-dns.alpha.kubernetes.io/cloudflare-proxied': 'false',
//    'traefik.ingress.kubernetes.io/router.tls.options': 'kube-system-no-client-auth@kubernetescrd',
//
