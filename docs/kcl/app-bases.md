# App Base Reference Spec

Pattern: `apps/<tenant>/<app>/base/`

App bases define the canonical configuration for an application. They are not independently renderable -- only overlays (environment directories) render them.

## Required Files

| File | Purpose |
|---|---|
| `main.k` | App definition; must export `app` (see Library Base for the exception) |
| `kcl.mod` | Package manifest |
| `kcl.mod.lock` | Lock file (committed). Chartless bases with no registry dependencies won't have one. |

### Optional Files

| File | Purpose |
|---|---|
| `values.yaml` | Helm chart values (one per chart; multi-chart apps may have `values-<chart>.yaml`) |
| `config/` | External config files for ConfigMaps (YAML, Python, shell scripts) |
| `tofu/` | OpenTofu workspace definitions |
| `*.k` (additional) | Supplementary definitions imported by `main.k` |

## main.k Contract

Must export a top-level `app` variable as a `frontend.App {}` instance. May also export auxiliary variables for overlay or sibling consumption (see Pattern 10).

```kcl
import file
import konfig.models.frontend
import konfig.files

import <tenant>_shared
import charts.<chart_name>

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "<app>"
    tenantName = <tenant>_shared.tenant.name

    charts.<chart_name> = <chart_name>.Chart {
        values: _values | <chart_name>.Values {}
    }
}
```

Multi-chart apps load separate values files per chart:

```kcl
_values = files.read_yaml(file.current(), "values.yaml")
_valuesSecond = files.read_yaml(file.current(), "values-second.yaml")

app = frontend.App {
    charts.second_chart = second_chart.Chart { values: _valuesSecond | second_chart.Values {} }
    charts.main_chart = main_chart.Chart { values: _values | main_chart.Values {} }
}
```

## kcl.mod Conventions

```toml
[package]
name = "<tenant>_<app>_base"
version = "0.1.0"

[dependencies]
<tenant>_shared = { path = "../../_tenant/shared" }
```

- Package name: `<tenant>_<app>_base` (hyphens become underscores).
- Single dependency on tenant shared, aliased as `<tenant>_shared`.
- Bases MUST NOT have a `[profile]` section. Only overlays and tenant dirs are renderable; bases are consumed as dependencies.

## values.yaml Convention

Every `values.yaml` MUST start with a YAML language server schema reference:

```yaml
# yaml-language-server: $schema=../../../../charts/<chart_name>/values.schema.json
```

The relative path depth (`../../../../`) varies by directory depth but always resolves to the chart's generated schema in `charts/`.

## KCL Assignment Semantics

The codebase uses both `:` and `=` when setting fields inside `frontend.App {}` blocks. These are NOT interchangeable in general:

- `=` is assignment/override -- replaces any existing value
- `:` is union/merge -- deep-merges with any existing value

Both produce the same result when setting a field for the first time (no prior value to merge with), which is why both appear in base `main.k` files. Within overlays, `:` is preferred for dict fields like `charts`, `extraResources`, and `configMaps` because it merges with the base rather than replacing it.

## frontend.App Schema Fields

Defined at `konfig/models/frontend/app.k`. Inherits from `common.Metadata` (`konfig/models/frontend/common/metadata.k`) which provides `name`, `labels`, `annotations`, and `namespace`. All fields optional except `name`.

| Field | Type | Usage |
|---|---|---|
| `name` | `str` | App name (required; inherited from Metadata) |
| `tenantName` | `str` | Tenant name, used to derive namespace |
| `fullName` | `str` | Default `"{tenantName}-{name}"`; overridable but rarely set explicitly |
| `namespace` | `str` | Default `"{tenantName}-{name}"`; override auto-generated namespace |
| `domainName` | `str` | Usually set at overlay level |
| `secretStore` | `str` | Default secret store name for ExternalSecrets |
| `charts` | `{str:helm.Chart}` | Helm chart instances |
| `configMaps` | `{str:ConfigMap}` | ConfigMap resources |
| `secrets` | `{str:Secret}` | Secret resources |
| `externalSecrets` | `{str:ExternalSecret}` | ExternalSecret resources |
| `routes` | `{str:Route}` | Gateway API routes |
| `networkPolicies` | `{str:NetworkPolicy}` | Cilium network policies |
| `ingresses` | `{str:Ingress}` | Ingress resources |
| `serviceAccounts` | `{str:ServiceAccount}` | ServiceAccount resources |
| `services` | `{str:Service}` | Service resources |
| `roles` | `{str:Role}` | Role resources |
| `clusterRoles` | `{str:ClusterRole}` | ClusterRole resources |
| `roleBindings` | `{str:RoleBinding}` | RoleBinding resources |
| `clusterRoleBindings` | `{str:ClusterRoleBinding}` | ClusterRoleBinding resources |
| `namespaceSecretStores` | `{str:NamespaceSecretStore}` | Namespace-scoped secret stores |
| `secretStores` | `{str:SecretStore}` | SecretStore resources |
| `grafanaDashboards` | `{str:GrafanaDashboard}` | Grafana dashboard resources |
| `extraResources` | `{str:any}` | Escape hatch for arbitrary K8s resources |

## Pattern Catalog

### 1. Simple Helm Chart

Most common. Just `values.yaml` + a Chart instance. No extra resources.

**Chartless variant** -- defines only `name` and `tenantName` with no charts, values, or extra resources. Used when all charts/resources are added at the overlay level.

### 2. Helm + NetworkPolicies

Adds pre-built policy templates from `konfig.models.templates.networkpolicy`.

```kcl
import konfig.models.templates.networkpolicy as npt

app = frontend.App {
    networkPolicies: {
        denyDefault = npt.denyDefault
        kubeDNSEgress = npt.kubeDNSEgress
        kubeAPIServerEgress = npt.kubeAPIServerEgress
        icmpV6Egress = npt.icmpV6Egress
        gatewayIngress = npt.envoyGatewayIngress
    }
    charts.<chart> = ...
}
```

Not all templates are used by every app -- each picks the subset it needs. Available templates include `denyDefault`, `kubeDNSEgress`, `kubeAPIServerEgress`, `icmpV6Egress`, `envoyGatewayIngress`.

### 3. Helm + ExternalSecrets

Uses `secret.ExternalSecret` for credentials from an external secret provider. Requires `secretStore` (usually from `<tenant>_shared.shared.secretStores.default.name`).

```kcl
import konfig.models.frontend.secret

_mySecret = secret.ExternalSecret {
    name = "secret-name"
    data = {
        KEY = { remoteRef.key = "VAULT_KEY" }
    }
}

app = frontend.App {
    secretStore = <tenant>_shared.shared.secretStores.default.name
    externalSecrets.mySecret = _mySecret
    ...
}
```

#### ExternalSecret Advanced Features

**Templated output** -- `target.template` renders secret data through Go templates. Used when the secret format differs from the source:

```kcl
_creds = secret.ExternalSecret {
    name = "argocd-credentials"
    data.REDIS_PASSWORD = {
        sourceRef.generatorRef = { name = "alphanumeric-password" }
    }
    target.template.data: {
        "redis-username" = "default"
        "redis-password" = "{{ .REDIS_PASSWORD }}"
    }
    target.template.metadata.labels: {
        "argocd.argoproj.io/secret-type" = "cluster"
    }
}
```

**Programmatic templating** -- `target.template.data` can use `json.encode()` to build structured secret content in KCL rather than Go templates:

```kcl
_s3Config = secret.ExternalSecret {
    name = "s3-config"
    data: {
        ACCESS_KEY = {}
        SECRET_KEY = {}
    }
    target.template.data: {
        config = json.encode({
            identities = [{
                name = "myapp"
                credentials = [{
                    accessKey = "{{.ACCESS_KEY}}"
                    secretKey = "{{.SECRET_KEY}}"
                }]
                actions = ["Read:my-bucket", "Write:my-bucket"]
            }]
        }, indent=2)
    }
}
```

**Non-default secret store** -- Override the app-level `secretStore` for a specific secret via `secretStoreRef`:

```kcl
_creds = secret.ExternalSecret {
    name = "main-credentials"
    secretStoreRef = _customStore.getRef()
    data.KEY = {}
}
```

**Base64 decoding** -- `remoteRef.decodingStrategy` decodes base64-encoded values:

```kcl
data."Cookie.pkl" = {
    remoteRef = {
        key = "MY_COOKIE"
        decodingStrategy = "Base64"
    }
}
```

**Helper methods**:
- `ExternalSecret.getSecretKeyEnvRef(key)` -- returns a `valueFrom.secretKeyRef` for use in env var lists
- `ExternalSecret.getSecretKeyRef(key)` -- returns a `secretKeyRef` for use in CRD specs (e.g. cert-manager solver config)
- `SecretStore.getRef()` -- returns a reference suitable for `secretStoreRef`

### 4. Helm + Gateway Routes

Exposes services via Envoy Gateway. Optionally adds OIDC auth.

```kcl
import konfig.models.frontend.gateway

app = frontend.App {
    routes.<name> = gateway.Route {
        gatewayRef = <tenant>_shared.tenant.gateways.default
        services.<svc> = { name = "...", port = ... }
        homepage = {
            name = "App Name"
            description = "What this app does"
            group = "Apps"
            icon = "app-icon"
            # weight: int -- optional ordering hint
        }
        security = {
            oidcClientRef = _oidcClient.name
            oidcIssuer = <tenant>_shared.tenant.oidcIssuer
        }
    }
    ...
}
```

The `homepage` block registers the route with the homepage dashboard. Fields: `name`, `description`, `group`, `icon`, `weight` (optional ordering).

The `names` field overrides the auto-generated route name list when the default (`[<app-name>]`) is not desired:

```kcl
routes.secondary = gateway.Route {
    name = "my-secondary-route"
    names = ["secondary"]
    ...
}
```

The `security` block is optional -- routes without it are publicly accessible.

The `gatewayRef` can target any gateway key defined on the tenant, not just `.default` (e.g. `gateways.public` for a public-facing gateway).

### 5. Raw CRD Manifests via extraResources

Uses chart-generated API types for CRDs (e.g. BGP config, database clusters, stream resources).

```kcl
import charts.<chart>.api.<version> as <alias>

_resource = <alias>.ResourceType {
    metadata: { ... }
    spec: { ... }
}

app = frontend.App {
    extraResources.resourceName = _resource
    ...
}
```

### 6. ConfigMaps from File Reads

Loads external files into ConfigMaps via `files.read_file()` and `files.read_yaml()`.

```kcl
import konfig.models.frontend.configmap

app = frontend.App {
    configMaps.config = configmap.ConfigMap {
        data: {
            "file.yaml" = files.read_file(file.current(), "config/file.yaml")
        }
    }
    ...
}
```

### 7. Post-Renderer Lambdas

Mutates Helm-rendered resources via lambda functions. Common uses include env var injection and post-render resource transforms.

```kcl
charts.<chart> = <chart>.Chart {
    values: _values | <chart>.Values {}
    postRenderer = lambda resource: helm.Resource -> helm.Resource {
        if resource.kind == "Deployment" and resource.metadata.name == "...":
            # mutate resource
        resource
    }
}
```

`utils.EnvBuilder` converts a `{str:str|valueFrom}` dict into a sorted env var list, useful inside post-renderers:

```kcl
import konfig.models.utils

postRenderer = lambda resource: helm.Resource -> helm.Resource {
    if resource.kind == "Deployment" and resource.metadata.name == "my-app":
        resource.spec.template.spec.containers[0].env = utils.EnvBuilder(_envVars) + [
            env for env in resource.spec.template.spec.containers[0].env
            if env.name not in [k for k in _envVars]
        ]
    resource
}
```

### 8. Multi-Chart and Multi-Provider Configurations

A single app base can declare multiple chart instances. Two sub-patterns:

**Multi-provider** -- multiple instances of the same chart type with different provider configs. The base exports auxiliary values and credentials; overlays assemble them into chart instances. The base itself may be chartless.

**Multi-chart** -- different chart types composed into one app.

### 9. Multi-File Bases

Additional `.k` files beyond `main.k` for complex apps. `main.k` imports them. Useful when a single file would be unwieldy (e.g. many CRD definitions).

### 10. Auxiliary Exports

Some bases export additional top-level variables alongside `app` for consumption by overlays or sibling apps. Unlike the Library Base pattern (which has no `app`), these bases follow the standard contract and add extra exports.

```kcl
# Exported alongside `app` for overlay use
appConfig = files.read_yaml(file.current(), "config/app.yaml")

app = frontend.App { ... }
```

Overlays import the base and access both `app` and the auxiliary exports, allowing cluster-specific customization of shared configuration.

### 11. RBAC Resources

Defines ClusterRoles and ClusterRoleBindings for apps that need cluster-wide permissions. Uses `getRef()` to link bindings to roles.

```kcl
clusterRoles.myapp = rbac.ClusterRole {
    name = name
    rules = [{ apiGroups = [""], resources = ["namespaces", "pods", "nodes"], verbs = ["get", "list"] }]
}
clusterRoleBindings.myapp = rbac.ClusterRoleBinding {
    name = name
    roleRef = clusterRoles.myapp.getRef()
    subjects = [{ kind = "ServiceAccount", name = name }]
}
```

## Library Base Pattern

`starr/qbt/base/` is a special "library" base:

- No tenant shared dependency -- depends only on `konfig`.
- Does NOT export `app` -- exports `values` and `oidcClient` instead.
- Has no overlays (no cluster directories).
- Consumed by sibling apps (`qbt-audio`, `qbt-movies`, `qbt-tv`) via cross-app import.

> **TODO:** this is a unique pattern that needs to be formalized as a first-class concept.

## Cross-App Imports

`qbt-audio`, `qbt-movies`, and `qbt-tv` each declare `qbt_base = { path = "../../qbt/base" }` in `kcl.mod` and import shared values/secrets from it. This is the only instance of cross-app imports in the codebase.

## Common Imports

Most app bases use some subset of:

- `file` -- `file.current()` path resolution
- `konfig.files` -- `read_yaml()`, `read_file()`
- `konfig.models.frontend` -- `App` schema
- `konfig.models.frontend.secret` -- `ExternalSecret`
- `konfig.models.frontend.gateway` -- `Route`
- `konfig.models.frontend.configmap` -- `ConfigMap`
- `konfig.models.frontend.networkpolicy` -- `NetworkPolicy`
- `konfig.models.templates.networkpolicy` -- pre-built policy templates
- `konfig.models.utils` -- `AppMetadataBuilder`, `EnvBuilder`
- `charts.<chart_name>` -- Helm chart wrappers
- `yaml` -- `yaml.encode()` for structured config in ConfigMaps/ExternalSecrets
- `json` -- `json.encode()` for structured secret data
- `konfig.strings` -- string utilities (`dedent`)
- `<tenant>_shared` -- tenant shared config
