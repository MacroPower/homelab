local k = import 'k.libsonnet';

local net = k.networking.v1;

local mergeMiddlewares(annotations, middleware) =
  if std.objectHas(annotations, 'traefik.ingress.kubernetes.io/router.middlewares')
  then
    '%s,%s' % [middleware, annotations['traefik.ingress.kubernetes.io/router.middlewares']]
  else
    middleware;

{
  new(name, namespace, host, serviceName, servicePort=80, tlsSecretName='', labels={}, annotations={})::
    local middlewareName = '%s-l5d-header-middleware' % name;

    local tls =
      if tlsSecretName == '' then
        net.ingress.mixin.spec.withTls(net.ingressTLS.withHosts(host))
      else
        net.ingress.mixin.spec.withTls(net.ingressTLS.withHosts(host)) +
        net.ingress.mixin.spec.withTls(net.ingressTLS.withSecretName(tlsSecretName));

    local ingress =
      net.ingress.new(name) +
      net.ingress.mixin.metadata.withLabelsMixin(labels) +
      net.ingress.mixin.metadata.withAnnotationsMixin(annotations {
        'traefik.ingress.kubernetes.io/router.middlewares': mergeMiddlewares(annotations, '%s-%s@kubernetescrd' % [namespace, middlewareName]),
      }) +
      tls +
      net.ingress.mixin.spec.withRules([
        net.ingressRule.mixin.withHost(host) +
        net.ingressRule.mixin.http.withPaths(
          net.httpIngressPath.withPath('/') +
          net.httpIngressPath.withPathType('Prefix') +
          net.httpIngressPath.backend.service.withName(serviceName) +
          net.httpIngressPath.backend.service.port.withNumber(servicePort)
        ),
      ]);


    [ingress, {
      apiVersion: 'traefik.containo.us/v1alpha1',
      kind: 'Middleware',
      metadata: {
        name: middlewareName,
        namespace: namespace,
      },
      spec: {
        headers: {
          customRequestHeaders: {
            'l5d-dst-override': '%s.%s.svc.cluster.local:%s' % [serviceName, namespace, servicePort],
          },
        },
      },
    }],
}
