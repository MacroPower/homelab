local database = import 'database/main.libsonnet';
local secrets = std.parseYaml(importstr 'secrets.yaml');
local terraform = import 'terraform/main.libsonnet';

database + secrets + terraform
