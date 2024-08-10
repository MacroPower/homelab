# Konfig

Kubernetes configuration in [KCL](https://www.kcl-lang.io/).

This is my personal implementation of [kcl-lang/konfig](https://github.com/kcl-lang/konfig). Konfig provides an out-of-the-box, highly abstract configuration interface. It simplifies writing user-side configuration code by abstracting and encapsulating models with more complex code into unified front-end models.

For more details, please refer to: [Model Overview](https://kcl-lang.io/docs/user_docs/guides/working-with-konfig/overview)

## Directory Structure

The overall structure of the configuration library is as follows:

```bash
.
├── kcl.mod             # konfig package metadata file
├── kcl.mod.lock        # konfig package metadata lock file
└── models
    ├── commons         # Common models
    ├── kube            # Cloud-native resource core models
    │   ├── backend         # Back-end models
    │   ├── frontend        # Front-end models
    │   │   ├── common          # Common front-end models
    │   │   ├── configmap       # ConfigMap
    │   │   ├── container       # Container
    │   │   ├── ingress         # Ingress
    │   │   ├── resource        # Resource
    │   │   ├── secret          # Secret
    │   │   ├── service         # Service
    │   │   ├── sidecar         # Sidecar
    │   │   ├── strategy        # strategy
    │   │   ├── volume          # Volume
    │   │   ├── app.k           # The `App` model
    │   │   └── tenant.k        # The `Tenant` model
    │   ├── metadata        # Kubernetes metadata
    │   ├── mixins          # Mixin
    │   ├── render          # Front-to-back-end renderers.
    │   ├── templates       # Data template
    │   └── utils
    └── metadata           # Common metadata
```

## Prerequisites

Install [KCL](https://kcl-lang.io/docs/user_docs/getting-started/install)

## License

Apache License Version 2.0
