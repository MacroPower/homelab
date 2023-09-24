// jsonnet base/twitch-channel-points-miner/main.jsonnet -J vendor --ext-str ingressAnnotations='{}' --ext-str ingressHost=''

local ns = import 'namespace.libsonnet';
local ingress = import 'ingress.libsonnet';
local runConfig = import 'run-config.libsonnet';
local secrets = import 'secrets.libsonnet';

[ns] + ingress + runConfig + secrets
