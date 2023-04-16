local k = import '../../lib/k.libsonnet';

local httpIngressPath = k.networking.v1.httpIngressPath;
local ingress = k.networking.v1.ingress;
local ingressRule = k.networking.v1.ingressRule;
local ingressTLS = k.networking.v1.ingressTLS;

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));

// local ingressHost = '';
// local ingressAnnotations = {};

ingress.new('ingress') +
ingress.mixin.metadata.withAnnotationsMixin(ingressAnnotations {
  'traefik.ingress.kubernetes.io/router.entrypoints': 'websecure',
})
+ ingress.mixin.spec.withTls(ingressTLS.withHosts(ingressHost))
+ ingress.mixin.spec.withRules([
  ingressRule.mixin.http.withPaths(
    httpIngressPath.withPath('/') +
    httpIngressPath.withPathType('Prefix') +
    httpIngressPath.backend.service.withName('goldilocks-dashboard') +
    httpIngressPath.backend.service.port.withNumber(80)
  )
  + ingressRule.mixin.withHost(ingressHost),
])
