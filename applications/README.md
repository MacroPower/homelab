# Applications

## Base

The `base` directory contains generic application definitions that can be
imported by any environment. They can be extended and/or manipulated as needed.

## Environments

### Adding Applications

Reference `application.libsonnet` in the environment's `main.jsonnet` file:

```jsonnet
local apps = [
  import '<app>/application.libsonnet',
]
```

### Referencing Bases

If you want to deploy a base without any changes, you can simply reference the
application file.

`environment/<env>/<app>/application.libsonnet`:

```jsonnet
import '../../../base/<app>/application.libsonnet'
```

### Modifying Bases

You can modify the base by importing the application and using its methods.

`environment/<env>/<app>/application.libsonnet`:

```jsonnet
local app = import '../../../base/<app>/application.libsonnet';

app.withChartParams({
  'gateway.serviceType': 'ClusterIP',
})
```

### Environment-Specific Apps

If you have lots of environment-specific resources, you can instead create an
application just for the environment, optionally using the base as a starting
point.

`environment/<env>/<app>/application.libsonnet`:

```jsonnet
local app = import '../../../base/<app>/application.libsonnet';

app.withBasePath('applications/environments/<env>/<app>')
```

or

```jsonnet
local app = import '../../../lib/app.libsonnet';

app.new(
  name='<app>',
  path='applications/environments/<env>/<app>',
  namespace='kube-system',
)
```

`environment/<env>/<app>/main.jsonnet`:

```jsonnet
[
  import 'cr.libsonnet',
  import '../../../base/<app>/namespace.libsonnet',
]
```

> Note: There's also no harm in having multiple bases for the same application,
> especially if the changes are not nessesarily environment-specific. For
> example, you might have two Jaeger bases, one with in-memory and one with
> Cassandra storage.
