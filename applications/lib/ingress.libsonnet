local k = import 'k.libsonnet';

local net = k.networking.v1;

{
  new(
    name,
    namespace,
    host,
    serviceName,
    servicePort=80,
    tlsSecretName='',
    httpIngressPath='/',
    httpIngressPathType='Prefix',
    localIngress=true,
    tailnetIngress=false,
    labels={},
    annotations={},
  )::
    local tls =
      if tlsSecretName == '' then
        net.ingress.mixin.spec.withTls(net.ingressTLS.withHosts(host))
      else
        net.ingress.mixin.spec.withTls(
          net.ingressTLS.withHosts(host) +
          net.ingressTLS.withSecretName(tlsSecretName)
        );

    local service = '%s.%s.svc.cluster.local:%s' % [serviceName, namespace, servicePort];

    local ingress =
      net.ingress.new(name) +
      net.ingress.mixin.metadata.withLabelsMixin(labels) +
      net.ingress.mixin.metadata.withAnnotationsMixin(annotations {
        [if !std.objectHas(annotations, 'gethomepage.dev/ping') then 'gethomepage.dev/ping']: 'http://%s' % service,
        [if !std.objectHas(annotations, 'gethomepage.dev/external') then 'gethomepage.dev/external']: 'true',
      }) +
      tls +
      net.ingress.mixin.spec.withRules([
        net.ingressRule.mixin.withHost(host) +
        net.ingressRule.mixin.http.withPaths(
          net.httpIngressPath.withPath(httpIngressPath) +
          net.httpIngressPath.withPathType(httpIngressPathType) +
          net.httpIngressPath.backend.service.withName(serviceName) +
          net.httpIngressPath.backend.service.port.withNumber(servicePort)
        ),
      ]);

    local tailnet =
      net.ingress.new('%s-tailnet' % name) +
      net.ingress.mixin.metadata.withLabelsMixin(labels) +
      net.ingress.mixin.spec.withIngressClassName('tailscale') +
      net.ingress.mixin.spec.withTls(net.ingressTLS.withHosts(host)) +
      net.ingress.mixin.spec.withRules([
        net.ingressRule.mixin.withHost(host) +
        net.ingressRule.mixin.http.withPaths(
          net.httpIngressPath.withPath(httpIngressPath) +
          net.httpIngressPath.withPathType(httpIngressPathType) +
          net.httpIngressPath.backend.service.withName(serviceName) +
          net.httpIngressPath.backend.service.port.withNumber(servicePort)
        ),
      ]);

    [
      x
      for x in [
        if localIngress then ingress else null,
        if tailnetIngress then tailnet else null,
      ]
      if x != null
    ],
}
