// jsonnet base/wakatime-exporter/main.jsonnet -J vendor

local ns = import 'namespace.libsonnet';
local secrets = import 'secrets.libsonnet';
local githubReadme = import 'github-readme/main.libsonnet';

[ns] + secrets + githubReadme
