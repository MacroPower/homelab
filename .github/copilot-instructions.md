# Copilot Instructions

## Architecture Overview

This is a multi-cluster Kubernetes homelab managed through GitOps using ArgoCD, with a unique KCL-based configuration system replacing traditional YAML/Helm patterns.

**Key Architecture Patterns:**
- **KCL-first Configuration**: Uses [KCL](https://www.kcl-lang.io/) as the primary configuration language through a custom `konfig` library, not raw YAML
- **Multi-cluster GitOps**: ArgoCD ApplicationSets deploy applications across multiple environments (mgmt, home, nas01, etc.)
- **Tenant-based Organization**: Applications are organized by "tenants" (argo, kube, o11y, etc.) with shared configuration

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
- **task kcl:render**: Primary tool for rendering KCL to YAML files for inspection (`task kcl:render APP=tenant/app F=env O=.debug/output.yaml`)
- **task kcl:chart:update**: Updates KCL chart definitions based on `charts/charts.k`
- **task**: Primary command runner (see `task -l` for all available tasks)

## Infrastructure Boundaries
- **Terraform**: Cloud infrastructure (Hetzner Cloud, networking)
- **Talos**: Immutable Kubernetes OS on bare metal
- **ArgoCD**: Application lifecycle management
- **KCL/Konfig**: Application configuration abstraction
- **ApplicationSets**: Multi-cluster application deployment via `.tenant.yaml` files

## Development Workflow

Render manifests:

```sh
task kcl:render APP=tenant/app F=env O=.debug/app.yaml
```

Update helm charts (run this after modifying `charts/charts.k`):

```sh
task kcl:chart:update
```
