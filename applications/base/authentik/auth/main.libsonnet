[]
+ std.parseYaml(importstr 'provider-config.yaml')
+ std.parseYaml(importstr 'roles.yaml')
+ std.parseYaml(importstr 'workspace.yaml')
+ std.parseYaml(importstr 'workspace-argocd.yaml')
+ std.parseYaml(importstr 'workspace-grafana.yaml')
+ import 'vars.libsonnet'
