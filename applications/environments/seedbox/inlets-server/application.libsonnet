local app = import '../../../base/inlets-server/application.libsonnet';

app.withExtVarsMixin({
  ingressHost: 'linkerd-tunnel-sb.macro.network',
})
