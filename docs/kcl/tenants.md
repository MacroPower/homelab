# Tenant Pattern Reference

Tenants partition applications under `apps/<tenant>/`. Each tenant declares its identity and shared resources in `_tenant/`, which all downstream apps depend on.

## Directory Layout

```
apps/<tenant>/_tenant/
  base/
    main.k
    kcl.mod
    kcl.mod.lock
    .tenant.yaml
  shared/
    main.k
    kcl.mod
    kcl.mod.lock
    .tenant.yaml
```

## Dependency Chain

```
app/base -> shared -> base -> konfig
```

Both `base/` and `shared/` include render entries in `[profile]`, so ArgoCD can render each one independently.

## base/

Defines the tenant identity. Exports `tenantConfiguration` as a `frontend.Tenant` instance.

### main.k -- simple variant

For tenants that only need a name.

```kcl
import konfig.models.frontend

tenantConfiguration = frontend.Tenant {
    name = "<tenant>"
}
```

### main.k -- gateway-enabled variant

For tenants whose apps expose routes via Envoy Gateway. Adds a default gateway and OIDC issuer.

```kcl
import konfig.models.frontend
import konfig.models.frontend.gateway

tenantConfiguration = frontend.Tenant {
    name = "<tenant>"
    gateways.default = gateway.Gateway {
        name = "cluster-gateway"
        namespace = "envoy-gateway"
    }
    oidcIssuer = "https://auth.jacobcolvin.com"
}
```

**Multi-gateway variant** -- tenants can define multiple gateways when apps need to target different ingress points:

```kcl
tenantConfiguration = frontend.Tenant {
    name = "<tenant>"
    gateways.default = gateway.Gateway {
        name = "cluster-gateway"
        namespace = "envoy-gateway"
    }
    gateways.public = gateway.Gateway {
        name = "public-gateway"
        namespace = "envoy-gateway"
    }
    oidcIssuer = "https://auth.jacobcolvin.com"
}
```

Apps choose which gateway to target via `tenant.gateways.default`, `tenant.gateways.public`, etc.

### kcl.mod

```toml
[package]
name = "<tenant>_tenant"
version = "0.1.0"

[dependencies]
konfig = { path = "../../../../konfig" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
```

## shared/

Imports the tenant base, re-exports it as `tenant`, and declares cluster-wide shared resources (secret stores, cluster roles). Exports `tenant` and `shared`.

### main.k -- with secret store

For tenants whose apps consume external secrets (Doppler).

```kcl
import <tenant>_tenant
import konfig.models.frontend

tenant = <tenant>_tenant.tenantConfiguration

shared = frontend.SharedApp {
    secretStores.default = {
        name = "<tenant>"
        provider.doppler.auth.secretRef.dopplerToken = {
            name = "doppler-credentials"
            key = "token"
            namespace = "kube-system"
        }
    }
}
```

### main.k -- without secret store

For tenants that don't need external secrets.

```kcl
import <tenant>_tenant
import konfig.models.frontend

tenant = <tenant>_tenant.tenantConfiguration

shared = frontend.SharedApp {}
```

### kcl.mod

The package name uses the `<tenant>_shared` convention. The dependency on `base/` uses the `<tenant>_tenant` package name.

```toml
[package]
name = "<tenant>_shared"
version = "0.1.0"

[dependencies]
<tenant>_tenant = { path = "../base" }

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
```

## .tenant.yaml

Identical in both `base/` and `shared/`. Consumed by the ArgoCD ApplicationSet system -- `base/` for the tenant-level Application, `shared/` for per-app ApplicationSet generation.

```yaml
# yaml-language-server: $schema=../../../../konfig/models/frontend/patch.schema.json

syncPolicy:
  automated:
    selfHeal: true
```

## Export Contract

| Directory | Exports | Type |
|-----------|---------|------|
| `base/` | `tenantConfiguration` | `frontend.Tenant` |
| `shared/` | `tenant` | re-exported `frontend.Tenant` from base |
| `shared/` | `shared` | `frontend.SharedApp` |

App bases import `shared/` (not `base/` directly) and receive both the tenant identity and shared resources.

## Relevant Schemas

- `frontend.Tenant` -- `konfig/models/frontend/tenant.k` -- fields: `name`, `secretStores`, `gateways`, `oidcIssuer`, `destinations`
- `frontend.SharedApp` -- `konfig/models/frontend/shared_app.k` -- fields: `tenantName`, `clusterRoles`, `clusterRoleBindings`, `secretStores`
