local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressSuffix = std.extVar('ingressSuffix');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

ingress.new(
  name='adguard-home-tailnet-ingress',
  namespace=ns.metadata.name,
  host='adguard-tailnet%s' % ingressSuffix,
  serviceName='adguard-home-tailnet',
  servicePort=3000,
  tailnetIngress=true,
  annotations=ingressAnnotations {
    'traefik.ingress.kubernetes.io/router.middlewares': 'authentik-ak-outpost@kubernetescrd',
  },
) +
ingress.new(
  name='dns-tailnet-ingress',
  namespace=ns.metadata.name,
  host='dns%s' % ingressSuffix,
  serviceName='adguard-home-tailnet',
  servicePort=3000,
  localIngress=false,
  tailnetIngress=true,
  tlsSecretName='dns-tailnet-cert',
  httpIngressPath='/dns-query',
  annotations=ingressAnnotations {
    'cert-manager.io/issuer': 'letsencrypt-prod',
  },
)
