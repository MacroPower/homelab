# KCL Overview

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

## Development Workflow

### 1. Development and Testing
Use the #kat agent tools for rendering and validation.

### 2. Helm Chart Integration
When using Helm charts, they're auto-generated as KCL wrappers.

First, update ./charts/charts.k, then run:
```bash
# Update chart definitions
task kcl:chart:update

# This updates charts/ directory with latest Helm chart schemas
```

### 3. Package Management
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
