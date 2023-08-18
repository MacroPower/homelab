local k = import '../../lib/k.libsonnet';

[
  k.apps.v1.deployment.new(
    name='local-ai-frontend',
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
        k.core.v1.envVar.new('API_HOST', 'http://local-ai.local-ai.svc:80'),
      ]),
    ]
  ) + k.apps.v1.deployment.metadata.withLabels({
    app: 'local-ai-frontend',
  }),
  k.core.v1.service.new(
    'local-ai-frontend',
    { app: 'local-ai-frontend' },
    k.core.v1.servicePort.new(3000, targetPort=3000)
  ),
]
