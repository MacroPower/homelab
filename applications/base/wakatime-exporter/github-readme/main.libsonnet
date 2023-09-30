local cronJob = import 'cronjob.libsonnet';
local secrets = import 'secrets.libsonnet';
local updateGraphConfig = import 'update-graph-config.libsonnet';

cronJob + secrets + updateGraphConfig
