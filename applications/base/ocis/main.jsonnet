// jsonnet base//main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local ldapAuth = std.parseYaml(importstr 'ldap-auth.yaml');
local uuids = std.parseYaml(importstr 'uuids.yaml');
local secrets = std.parseYaml(importstr 'secrets.yaml');
local patchOcisOidc = std.parseYaml(importstr 'patch-ocis-oidc.yaml');

[ns] + ldapAuth + uuids + secrets + patchOcisOidc
