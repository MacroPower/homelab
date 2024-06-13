// jsonnet base//main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local ldapAuth = std.parseYaml(importstr 'ldap-auth.yaml');

[ns] + ldapAuth
