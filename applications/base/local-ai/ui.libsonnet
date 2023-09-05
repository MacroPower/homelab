local k = import '../../lib/k.libsonnet';

local name = 'local-ai-frontend';
local labels = { app: name };

[
  k.apps.v1.deployment.new(
    name=name,
    replicas=1,
    containers=[
      k.core.v1.container.new(
        name='localai-frontend',
        image='quay.io/go-skynet/localai-frontend:master',
      ) +
      k.core.v1.container.withPorts(
        k.core.v1.containerPort.new(3000)
      ) +
      k.core.v1.container.withEnv([
        k.core.v1.envVar.new('API_HOST', 'https://local-ai.home.macro.network/api'),
      ]),
    ]
  ) + k.apps.v1.deployment.metadata.withLabels(labels)
  + k.apps.v1.deployment.spec.template.metadata.withLabels(labels)
  + k.apps.v1.deployment.spec.selector.withMatchLabels(labels),
  k.core.v1.service.new(
    'local-ai-frontend',
    labels,
    k.core.v1.servicePort.new(3000, targetPort=3000)
  ),
]
