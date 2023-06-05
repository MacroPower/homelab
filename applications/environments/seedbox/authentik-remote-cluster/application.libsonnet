local app = import '../../../base/authentik-remote-cluster/application.libsonnet';

app.withExtVarsMixin({
  ingressHost: 'authentik.macro.network',
})
