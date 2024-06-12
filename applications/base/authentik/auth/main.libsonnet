[]
+ std.parseYaml(importstr 'provider-config.yaml')
+ std.parseYaml(importstr 'roles.yaml')
+ std.parseYaml(importstr 'workspace-argo-workflows.yaml')
+ std.parseYaml(importstr 'workspace-argocd.yaml')
+ std.parseYaml(importstr 'workspace-certs.yaml')
+ std.parseYaml(importstr 'workspace-grafana.yaml')
+ std.parseYaml(importstr 'workspace-ocis.yaml')
+ std.parseYaml(importstr 'workspace.yaml')
+ import 'vars.libsonnet'
