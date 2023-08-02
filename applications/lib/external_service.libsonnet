local k = import 'k.libsonnet';

local service_monitor = import 'service_monitor.libsonnet';

local net = k.networking.v1;
local core = k.core.v1;

{
  new(name, namespace, ipAddress, portName, port, monitor=true)::
    local endpoint =
      core.endpoints.new(name) +
      core.endpoints.mixin.metadata.withLabelsMixin({
        'app.kubernetes.io/name': name,
      }) +
      core.endpoints.withSubsets(
        core.endpointSubset.withAddresses(
          core.endpointAddress.withIp(ipAddress)
        ) +
        core.endpointSubset.withPorts(
          core.endpointPort.withName(portName) +
          core.endpointPort.withPort(port)
        )
      );

    local servicePort =
      core.servicePort.withName(portName) +
      core.servicePort.withPort(port) +
      core.servicePort.withTargetPort(port);

    local service =
      core.service.newWithoutSelector(name) +
      core.service.spec.withPorts(servicePort) +
      core.service.mixin.metadata.withLabelsMixin({
        'app.kubernetes.io/name': name,
      });

    local sm =
      service_monitor.new(
        name,
        namespace,
        matchLabels={
          'app.kubernetes.io/name': name,
        },
        endpoints=[{
          interval: '60s',
          port: portName,
        }]
      );

    if monitor then
      [service, endpoint, sm]
    else
      [service, endpoint],
}
