# App Overlay Spec

Overlays live at `apps/<tenant>/<app>/<cluster>/` and represent the
renderable, deployable unit for a specific cluster. They merge
cluster-specific configuration onto a shared base app definition.

## Required Files

| File | Purpose |
|------|---------|
| `main.k` | Overlay definition; exports `app` |
| `kcl.mod` | Package manifest with base dependency and `[profile]` entries |
| `kcl.mod.lock` | Committed lockfile |
| `.app.yaml` | ArgoCD sync policy (schema-validated) |

### Optional Files

| File / Dir | Purpose |
|------------|---------|
| `values.yaml` | Cluster-specific Helm value overrides, deep-merged onto base values |
| `config/` | Cluster-specific config files (read via `files.read_yaml`, etc.) |
| `*.sh` | Shell scripts embedded into resources via `file.read()` |

## main.k

Must export a top-level `app` variable. The merge operator (`|`) overlays
cluster-specific fields onto the base:

```kcl
app = <tenant>_<app>_base.app | {
    # overlay additions/overrides
}
```

### Standard Values Merge

The canonical pattern deep-merges base Helm values with overlay values,
then pipes through the typed `Values` schema for validation:

```kcl
import file
import konfig.files
import konfig.objects

import <tenant>_<app>_base
import charts.<chart>

_baseValues = <tenant>_<app>_base.app.charts.<chart>.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = <tenant>_<app>_base.app | {
    charts.<chart>.values = _values | <chart>.Values {}
}
```

`objects.json_merge_patch` performs RFC 7396 deep merge. The trailing
`| <chart>.Values {}` pipe validates the merged result against the
chart's generated KCL schema.

## kcl.mod

```toml
[package]
name = "<tenant>_<app>_<cluster>"
version = "0.1.0"

[dependencies]
<tenant>_<app>_base = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
```

Rules:
- Package name uses underscores (hyphens in app/tenant names become `_`).
- Always depends on the app's base package.
- `[profile]` with `render.k` is mandatory -- overlays are the renderable units (bases are not).
- Add a `cluster` dependency when the overlay references cluster-specific identifiers:
  ```toml
  cluster = { path = "../../../../clusters/<cluster>" }
  ```

## .app.yaml

Uniform across all overlays:

```yaml
# yaml-language-server: $schema=../../../../konfig/models/frontend/patch.schema.json

syncPolicy:
  automated:
    selfHeal: true
```

Schema-validated against `konfig/models/frontend/patch.schema.json`.
Consumed by ArgoCD ApplicationSets to configure sync policy.
The schema also permits `ignoreDifferences`, `info`, and `source.targetRevision` fields.

## values.yaml Convention

Most overlay `values.yaml` files are empty overrides:

```yaml
# yaml-language-server: $schema=../../../../charts/<chart_name>/values.schema.json

{}
```

The schema reference MUST match the chart used by the base. An empty `{}` means the overlay inherits all base values unchanged. Non-empty overrides are deep-merged onto base values via `objects.json_merge_patch`.

Overlays without a Helm chart have no `values.yaml`.

## Cluster Config

Cluster packages at `clusters/<cluster>/main.k` export:

```kcl
NAME = "main"
DOMAIN_NAME = "main.cin.macro.network"
FRIENDLY_NAME = "Main"
```

Import via `import cluster` (requires the `cluster` dependency in `kcl.mod`).
Only needed when the overlay uses domain names, hostnames, or
cluster-specific identifiers.

## Merge Pattern Catalog

### 0. Pass-Through

No overrides at all. The overlay exists solely because the ArgoCD ApplicationSet requires an overlay directory with `.app.yaml` for deployment targeting.

```kcl
import <tenant>_<app>_base

app = <tenant>_<app>_base.app | {}
```

### 0b. Domain-Only

Sets `domainName` from cluster config but applies no value overrides.

```kcl
import cluster
import <tenant>_<app>_base

app = <tenant>_<app>_base.app | {
    domainName = cluster.DOMAIN_NAME
}
```

### 1. Values-Only

No cluster dependency. Merges Helm values only.

```kcl
app = <base>.app | {
    charts.<chart>.values = _values | <chart>.Values {}
}
```

**Inline variant** -- some overlays skip `values.yaml` and override values directly in KCL:

```kcl
app = <base>.app | {
    charts.<chart>.values = _baseValues | <chart>.Values {
        replicaCount = 2
    }
}
```

### 2. Values + Domain Name

Sets `domainName` from cluster config for child resources.

```kcl
import cluster

app = <base>.app | {
    domainName = cluster.DOMAIN_NAME
    charts.<chart>.values = _values | <chart>.Values {}
}
```

### 3. Values + Gateway Routes

Adds HTTP routes with hostnames derived from the cluster domain.

```kcl
app = <base>.app | {
    domainName = cluster.DOMAIN_NAME
    routes.<name> = gateway.Route {
        hostnames = ["app.jacobcolvin.com"]
        gatewayRef = { name = "public-gateway"; namespace = "envoy-gateway" }
        services.<svc> = { name = "<svc-name>"; port = 80 }
    }
    charts.<chart>.values = _values
}
```

### 4. Values + Certificates

Adds TLS certificates with cluster-specific DNS names.

```kcl
app = <base>.app | {
    domainName = cluster.DOMAIN_NAME
    extraResources.cert = certmanagerv1.Certificate {
        spec.dnsNames = ["*.${cluster.DOMAIN_NAME}"]
    }
    charts.<chart>.values = _values
}
```

### 5. Values + Cluster-Specific extraResources

Resources that differ per cluster (IP pools, BGP config, storage classes, etc.). Overlays can import chart API types or raw `k8s.api.*` types for constructing resources directly.

```kcl
app = <base>.app | {
    extraResources.ipPool = ciliumv2.CiliumLoadBalancerIPPool {
        spec.blocks = [{ cidr = "10.10.40.0/28" }]
    }
    charts.<chart>.values = _values
}
```

Overlays can also generate resources via dict comprehensions:

```kcl
_hosts = ["node01", "node02", "node03"]

_diskPools = {"diskPool_${hostname}": {
    apiVersion = "example.io/v1"
    kind = "DiskPool"
    metadata.name = "pool-${hostname}"
    spec.node = hostname
    spec.disks = ["aio:///dev/disk/by-partlabel/pool"]
} for hostname in _hosts}

app = <base>.app | {
    extraResources: { ... } | _diskPools
}
```

Shell scripts can be embedded via `file.read()`:

```kcl
command = ["/bin/bash", "-c", file.read(files.abs_path(file.current(), "init.sh"))]
```

### 6. Values + ConfigMaps with Cluster Data

Overrides ConfigMap contents with cluster-specific configuration.

```kcl
app = <base>.app | {
    domainName = cluster.DOMAIN_NAME
    configMaps.<name> = configmap.ConfigMap {
        data: {
            "config.yaml" = yaml.encode(_config | {
                upstream_dns = ["10.10.0.1"]
                tls.server_name = "dns.${cluster.DOMAIN_NAME}"
            })
        }
    }
}
```

### 7. Overlay Adds New Resource Types

Introduces resource types not present in the base. Most commonly network policies, but also secret stores, external secrets, or routes.

```kcl
import konfig.models.frontend.networkpolicy
import konfig.models.templates.networkpolicy as npt

app = <base>.app | {
    networkPolicies: {
        denyDefault = npt.denyDefault
        kubeDNSEgress = npt.kubeDNSEgress
        icmpV6Egress = npt.icmpV6Egress
        customEgress = networkpolicy.NetworkPolicy {
            name = "custom-egress"
            egress = [{
                toEndpoints = [{
                    matchLabels = {
                        "io.kubernetes.pod.namespace" = "target-namespace"
                        "app.kubernetes.io/component" = "gateway"
                    }
                }]
            }]
        }
    }
}
```

Overlays can also add `secretStores` or `externalSecrets` at the overlay level:

```kcl
app = <base>.app | {
    secretStores.custom = secret.SecretStore { ... }
    externalSecrets.creds = _creds
}
```

ExternalSecrets added at the overlay level can inject cluster-specific credentials into Helm values via `getSecretKeyEnvRef()`:

```kcl
_s3Config = secret.ExternalSecret {
    name = "s3-config"
    data.S3_ACCESS_KEY = { remoteRef.key = "MIMIR_S3_ACCESS_KEY" }
}

app = <base>.app | {
    externalSecrets.s3Config = _s3Config
    charts.<chart>.values = _values | <chart>.Values {
        global.extraEnv = [{
            name = "S3_ACCESS_KEY"
            valueFrom = _s3Config.getSecretKeyEnvRef("S3_ACCESS_KEY")
        }]
    }
}
```

### 8. Overlay Consumes Base Auxiliary Exports

Overlays can import any export from their base, not just `app`. This is how base auxiliary exports (see app-bases.md Pattern 10) flow into overlays:

```kcl
import <tenant>_<app>_base

_appConfig = <tenant>_<app>_base.appConfig

app = <tenant>_<app>_base.app | {
    configMaps.appConfig = configmap.ConfigMap {
        data."config.yaml" = yaml.encode(_appConfig | {
            tls.server_name = "app.${domainName}"
            upstream = [...]
        })
    }
}
```

**Assembly sub-pattern** -- when the base is chartless, the overlay assembles the entire app by pulling credentials, values, and chart instances from auxiliary exports. This is the only overlay pattern that introduces charts not present in the base:

```kcl
import <tenant>_<app>_base
import charts.<chart>

app = <tenant>_<app>_base.app | {
    externalSecrets: {
        providerACreds = <tenant>_<app>_base.providerACreds
        providerBCreds = <tenant>_<app>_base.providerBCreds
    }
    charts: {
        provider_a = <chart>.Chart {
            values: <tenant>_<app>_base.providerAValues | { ... }
        }
    }
}
```

### 9. Overlay Adds Gateway Routes

Routes can be defined entirely at the overlay level when they are cluster-specific. Some use tenant gateway refs, others hardcode gateway details:

```kcl
# Using tenant gateway ref (standard)
routes.myapp = gateway.Route {
    gatewayRef = <tenant>_shared.tenant.gateways.default
    ...
}

# Hardcoded gateway ref (when route targets a non-tenant gateway)
routes.myapp = gateway.Route {
    hostnames = ["app.example.com"]
    gatewayRef = { name = "public-gateway", namespace = "envoy-gateway" }
    services.server = { name = "my-app-server", port = 80 }
}
```

Use a hardcoded `gatewayRef` when the tenant has no gateway configured or when targeting a non-default gateway.

## Common Imports

| Import | Use |
|--------|-----|
| `file` | Path resolution for `file.current()` |
| `konfig.files` | `read_yaml()` for loading values/config files |
| `konfig.objects` | `json_merge_patch()` for deep value merging |
| `<tenant>_<app>_base` | The base app definition |
| `charts.<chart>` | `Values` schema for pipe validation |
| `cluster` | Cluster-specific identifiers (`DOMAIN_NAME`, `NAME`) |
| `konfig.models.frontend.gateway` | `gateway.Route` for HTTP routes |
| `konfig.models.frontend.secret` | `SecretStore`, `ExternalSecret` |
| `konfig.models.frontend.configmap` | `ConfigMap` for config overrides |
| `konfig.models.frontend.networkpolicy` | Custom `NetworkPolicy` definitions |
| `konfig.models.templates.networkpolicy` | Pre-built policy templates (`denyDefault`, `kubeDNSEgress`, etc.) |
| `yaml` | `yaml.encode()` for ConfigMap data |
| `json` | `json.encode()` for structured secret/config data |
| `charts.<chart>.api.*` | CRD types from chart API packages |
| `k8s.api.*` | Raw Kubernetes API types (`apps/v1`, `core/v1`, `storage/v1`) |
