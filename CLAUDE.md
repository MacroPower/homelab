# Agent Instructions

## Overview
This is a multi-cluster Kubernetes homelab managed through GitOps using ArgoCD, with a unique KCL-based configuration system replacing traditional YAML/Helm patterns.

**Key Architecture Patterns:**
- **KCL-first Configuration**: Uses [KCL](https://www.kcl-lang.io/) as the primary configuration language through a custom `konfig` library, not raw YAML
- **Multi-cluster GitOps**: ArgoCD ApplicationSets deploy applications across multiple environments (mgmt, home, nas01, etc.)
- **Tenant-based Organization**: Applications are organized by "tenants" (argo, kube, o11y, etc.) with shared configuration

KCL is a CNCF Sandbox project that provides:
- **Type Safety**: Strong typing with schema validation
- **Configuration Abstraction**: High-level abstractions over complex Kubernetes resources
- **Python-like Syntax**: Familiar syntax with comprehensions, functions, and OOP concepts
- **Policy Constraints**: Built-in validation and policy enforcement
- **Multi-language Integration**: Can generate YAML, JSON, and integrate with various tools

## Directory Structure
```
├── apps/        # KCL-based applications
├── appsets/     # ArgoCD ApplicationSets
├── bootstrap/   # KCL cluster bootstrapping files
├── konfig/      # KCL library for Kubernetes abstractions
├── charts/      # Helm chart KCL wrappers (auto-generated)
├── clusters/    # Talos cluster configurations
└── terraform/   # Terraform for infrastructure
```

## Key Tools & Commands

Task is the primary command runner (see `task -l` for all available tasks)

```sh
# Re-generate chart schemas after updates to charts.k
kcl chart update -c <chart_key>
```

## Infrastructure Boundaries
- **Terraform**: Cloud infrastructure (Hetzner Cloud, networking)
- **Talos**: Immutable Kubernetes OS on bare metal
- **ArgoCD**: Application lifecycle management
- **KCL/Konfig**: Application configuration abstraction
- **ApplicationSets**: Multi-cluster application deployment via `.tenant.yaml` and `.app.yaml` files

## Development Workflow
- IMPORTANT: If you update `charts/charts.k`, make sure to run `kcl chart update -c <chart_key>` to re-generate files.

## KCL Application Overview
This homelab uses a **KCL-first configuration approach** with a custom `konfig` library for Kubernetes abstractions:
```
├── apps/                   # Current KCL-based applications
│   ├── argo/               # Tenant: ArgoCD apps
│   ├── kube/               # Tenant: Core Kubernetes apps
│   ├── o11y/               # Tenant: Observability apps
│   └── {tenant}/
│       ├── _tenant/        # Tenant-level shared config
│       │   ├── base/       # Base tenant definition
│       │   └── shared/     # Shared tenant resources
│       └── {app}/
│           ├── base/       # Base app configuration
│           └── {env}/      # Environment-specific config
├── konfig/                 # Custom KCL library for Kubernetes abstractions
└── charts/                 # Auto-generated Helm chart KCL wrappers
```
For more information, see:
- [Overview](./docs/kcl/overview.md)
- [Tenant Patterns](./docs/kcl/tenants.md)
- [App Base Patterns](./docs/kcl/app-bases.md)
- [App Overlay Patterns](./docs/kcl/app-overlays.md)
