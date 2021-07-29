local k = import 'lib/k.libsonnet',
      container = k.core.v1.container,
      containerPort = k.core.v1.containerPort,
      persistentVolumeClaim = k.core.v1.persistentVolumeClaim,
      service = k.core.v1.service,
      statefulSet = k.apps.v1.statefulSet;
local util = (import 'github.com/grafana/jsonnet-libs/ksonnet-util/util.libsonnet').withK(k);

{
  _config+:: {
    accessKey: {
      name: 'minio-key',
      key: 'minio-access-key',
    },
    secretKey: {
      name: 'minio-key',
      key: 'minio-secret-key',
    },
    bucketNames: error 'must set bucketNames',
  },

  minio: {
    local buckets = $._config.bucketNames,

    container::
      container.new('minio', 'minio/minio')
      + container.withCommand(
        ['/bin/sh', '-euc', std.join(' ', ['mkdir', '-p'] + ['/data/' + bucket for bucket in buckets] + ['&&', 'minio', 'server', '/data'])]
      )
      + container.withEnv([
        { name: 'MINIO_ACCESS_KEY', valueFrom: { secretKeyRef: $._config.accessKey } },
        { name: 'MINIO_SECRET_KEY', valueFrom: { secretKeyRef: $._config.secretKey } },
        { name: 'MINIO_PROMETHEUS_AUTH_TYPE', value: 'public' },
      ])
      + container.withImagePullPolicy('Always')
      + container.withPorts(containerPort.newNamed(9000, 'http-metrics'))
      + container.withVolumeMounts([{ name: 'minio-data', mountPath: '/data' }]),


    persistentVolumeClaim::
      persistentVolumeClaim.new('minio-data')
      + persistentVolumeClaim.spec.resources.withRequests({ storage: '10Gi' })
      + persistentVolumeClaim.spec.withAccessModes(['ReadWriteOnce']),

    // TODO: even though this is a StatefulSet, minio is not configured to run in a distributed mode.
    // You cannot yet scale the minio StatefulSet to increase storage or compute.
    statefulSet:
      statefulSet.new('minio', 1, [self.container], self.persistentVolumeClaim)
      + statefulSet.spec.withServiceName(self.service.metadata.name)
      + statefulSet.spec.template.metadata.withAnnotationsMixin({ 'prometheus.io/path': '/minio/v2/metrics/cluster' }),

    service:
      util.serviceFor(self.statefulSet),
  },
}
