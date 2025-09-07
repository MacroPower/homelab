---
description: 'Instructions for writing KCL code following idiomatic practices and community standards'
applyTo: '**/*.k,**/kcl.mod,**/kcl.sum'
---

# KCL Development Instructions

KCL is a CNCF Sandbox project that provides:
- **Type Safety**: Strong typing with schema validation
- **Configuration Abstraction**: High-level abstractions over complex Kubernetes resources
- **Python-like Syntax**: Familiar syntax with comprehensions, functions, and OOP concepts
- **Policy Constraints**: Built-in validation and policy enforcement
- **Multi-language Integration**: Can generate YAML, JSON, and integrate with various tools

## Project Architecture Overview

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

## KCL Language Fundamentals

### Basic Syntax

```kcl
# Variables and basic types
name = "nginx"
replicas = 3
enabled = True
resources = Undefined  # Similar to null/None

# Lists and dictionaries
ports = [80, 443, 8080]
labels = {
    app = "nginx"
    version = "1.21"
}

# String interpolation
image = "nginx:${version}"
```

### Schema Definitions

```kcl
# Define a schema (similar to a class/struct)
schema Container:
    """Container configuration schema."""
    name: str
    image: str
    ports?: [int] = []  # Optional with default
    env?: {str: str}    # Optional environment variables

    # Validation constraints
    check:
        len(name) > 0, "Container name cannot be empty"
        len(ports) <= 10, "Too many ports defined"

# Instantiate schema
webContainer = Container {
    name = "web"
    image = "nginx:1.21"
    ports = [80, 443]
    env = {
        NODE_ENV = "production"
    }
}
```

### List and Dict Comprehensions

```kcl
# List comprehensions (Python-like syntax)
numbers = [1, 2, 3, 4, 5]
doubled = [x * 2 for x in numbers]                    # [2, 4, 6, 8, 10]
evens = [x for x in numbers if x % 2 == 0]            # [2, 4]

# Dict comprehensions
services = ["api", "web", "db"]
serviceMap = {s: "${s}-service" for s in services}    # {api: "api-service", ...}

# Nested comprehensions
matrix = [[x, y] for x in range(3) if x % 2 == 0 for y in range(3) if y > x]
```

### Conditional Expressions and Control Flow

```kcl
# Ternary operator
environment = "prod"
replicas = 3 if environment == "prod" else 1

# If statements in schemas/configs
schema App:
    name: str
    environment: str

    if environment == "prod":
        replicas = 5
        resources = {cpu: "1000m", memory: "2Gi"}
    else:
        replicas = 1
        resources = {cpu: "100m", memory: "128Mi"}
```

### Import System

```kcl
# Import modules
import yaml
import json

# Import from file/package paths
import charts.nginx
import konfig.models.frontend

# Import with alias
import charts.prometheus_operator as prometheus
import konfig.files as kutils
```

## Application Structure Patterns

### 1. Base Application Pattern

**File**: `apps/{tenant}/{app}/base/main.k`

```kcl
import file

import konfig.models.frontend
import konfig.files

import {tenant}_tenant  # Import tenant shared config
import charts.{chart_name}

# Read values from YAML file
_values = files.read_yaml(file.current(), "values.yaml")

# Define the application
app = frontend.App {
    name = "{app}"
    tenantName = {tenant}_tenant.tenant.name

    # Configure charts
    charts.{chart_name} = {chart_name}.Chart {
        values: _values | {chart_name}.Values {}
    }
}
```

**Dependencies in `kcl.mod`**:
```toml
[package]
name = "{tenant}_{app}_base"
version = "0.1.0"

[dependencies]
{tenant} = { path = "../../_tenant/shared" }
```

### 2. Environment Extension Pattern

**File**: `apps/{tenant}/{app}/{env}/main.k`

```kcl
import file

import konfig.files
import konfig.objects

import {tenant}_{app}_base

# Merge base values with environment-specific values
_baseValues = {tenant}_{app}_base.app.charts.{chart}.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Extend the base app with environment-specific configuration
app = {tenant}_{app}_base.app | {
    charts.{chart}.values = _values

    # Add environment-specific resources
    secrets.mySecret = frontend.secret.ExternalSecret {
        name = "prod-secrets"
        # ... production secret configuration
    }
}
```

**Dependencies in `kcl.mod`**:
```toml
[package]
name = "{tenant}_{app}_{env}"
version = "0.1.0"

[dependencies]
{tenant}_{app}_base = { path = "../base" }
cluster = { path = "../../../../clusters/{env}" }  # If cluster-specific config needed

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
```

### 3. Tenant Configuration Pattern

**File**: `apps/{tenant}/_tenant/base/main.k`

```kcl
import konfig.models.frontend as frontend

tenantConfiguration = frontend.Tenant {
    name = "{tenant}"

    # Define shared resources for this tenant
    secretStores = {
        default = frontend.secret.ClusterSecretStore {
            name = "{tenant}-vault"
            # ... configuration
        }
    }
}
```

**File**: `apps/{tenant}/_tenant/shared/main.k`

```kcl
import {tenant}_tenant

# Re-export tenant and create shared resources
tenant = {tenant}_tenant.tenantConfiguration

shared = {
    secretStores = tenant.secretStores
    # ... other shared resources
}
```

## Best Practices

### 1. File Organization

- **One schema per file**: Keep schema definitions focused and maintainable
- **Descriptive naming**: Use clear, descriptive names for variables and schemas
- **Consistent imports**: Group imports logically (stdlib, konfig, other)

```kcl
import file

import konfig.models.frontend
import konfig.files

import local_module
import charts.grafana
```

### 2. Schema Design

```kcl
schema ServiceConfig:
    """Configuration for a Kubernetes service.

    Attributes:
        name: Service name, must be DNS-1035 compliant
        ports: List of service ports
        type: Service type (ClusterIP, LoadBalancer, etc.)
    """
    name: str
    ports: [ServicePort]
    type?: str = "ClusterIP"

    # Validation rules
    check:
        len(name) > 0 and len(name) <= 63, "Invalid service name length"
        len(ports) > 0, "Service must define at least one port"
        type in ["ClusterIP", "LoadBalancer", "NodePort"], "Invalid service type"

schema ServicePort:
    """Service port configuration."""
    port: int
    targetPort?: int | str
    protocol?: str = "TCP"

    check:
        1 <= port <= 65535, "Port must be between 1 and 65535"
        protocol in ["TCP", "UDP"], "Protocol must be TCP or UDP"
```

### 3. Value Management

Prefer to use values.yaml files for configuration, but also allow inline definitions for quick overrides or where expressions or references are needed.

### 4. Utility Functions

```kcl
# Create reusable utility functions
ensureList = lambda value: any -> [any] {
    """Ensure a value is a list."""
    [value] if typeof(value) != "list" else value
}

generateLabels = lambda name: str, app: str, version: str = "latest" -> {str: str} {
    """Generate standard Kubernetes labels."""
    {
        "app.kubernetes.io/name" = name
        "app.kubernetes.io/instance" = app
        "app.kubernetes.io/version" = version
        "app.kubernetes.io/managed-by" = "kcl"
    }
}

# Usage
myLabels = generateLabels("nginx", "web-server", "1.21")
```

## Development Workflow

### 1. Creating New Applications

Use the project's task automation:

```bash
# Create a new application with environments
task kcl:create-app TENANT=kube APP=myapp ENV=mgmt,main

# This creates:
# apps/kube/myapp/base/
# apps/kube/myapp/mgmt/
# apps/kube/myapp/main/
```

### 2. Development and Testing

Use the #kat agent tools for rendering and validation.

### 3. Helm Chart Integration

When using Helm charts, they're auto-generated as KCL wrappers.

First, update ./charts/charts.k, then run:

```bash
# Update chart definitions
task kcl:chart:update

# This updates charts/ directory with latest Helm chart schemas
```

### 4. Package Management

```toml
# kcl.mod - Package definition
[package]
name = "my_package"
version = "0.1.0"

[dependencies]
konfig = { path = "../../../konfig" }           # Local dependency
k8s = "1.31.2"                                  # Registry dependency
charts = { path = "../charts" }                 # Chart wrappers

[profile]
entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]
```

## Migration from Legacy Code

When updating applications from the deprecated `_legacy_apps/` directory:

1. **DO NOT** modify anything in `_legacy_apps/` - it's deprecated
2. Create new KCL structure in `apps/`
3. Use `konfig` frontend models instead of raw Kubernetes YAML
4. Migrate Jsonnet logic to KCL schemas and functions
5. Test thoroughly with `task kcl:render`
