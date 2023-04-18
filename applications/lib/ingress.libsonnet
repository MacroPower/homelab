local k = import 'k.libsonnet';

local net = k.networking.v1;

{
  new(name, host, serviceName, servicePort=80, labels={}, annotations={})::
    net.ingress.new(name) +
    net.ingress.mixin.metadata.withLabelsMixin(labels) +
    net.ingress.mixin.metadata.withAnnotationsMixin(annotations) +
    net.ingress.mixin.spec.withTls(net.ingressTLS.withHosts(host)) +
    net.ingress.mixin.spec.withRules([
      net.ingressRule.mixin.withHost(host) +
      net.ingressRule.mixin.http.withPaths(
        net.httpIngressPath.withPath('/') +
        net.httpIngressPath.withPathType('Prefix') +
        net.httpIngressPath.backend.service.withName(serviceName) +
        net.httpIngressPath.backend.service.port.withNumber(servicePort)
      ),
    ]),
}
