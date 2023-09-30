local k = import '../../../lib/k.libsonnet';

local cronJob = k.batch.v1.cronJob;
local container = k.core.v1.container;
local volumeMount = k.core.v1.volumeMount;
local volume = k.core.v1.volume;
local envVar = k.core.v1.envVar;

[
  cronJob.new('update-github-readme', '0 * * * *', [
    container.new('update-github-readme', 'golang:1.21') +
    container.mixin.withCommand([
      '/bin/bash',
      '/scripts/update-graph.sh',
    ]) +
    container.mixin.withImagePullPolicy('Always') +
    container.mixin.withVolumeMounts([
      volumeMount.new(
        name='github-readme-scripts',
        mountPath='/scripts',
      ),
    ]) +
    container.mixin.withEnv([
      envVar.fromSecretRef('WAKATIME_GITHUB_REPO_URL', 'github-readme-credentials', 'WAKATIME_GITHUB_REPO_URL'),
    ]),
  ]) +
  cronJob.mixin.spec.withSuccessfulJobsHistoryLimit(1) +
  cronJob.mixin.spec.withFailedJobsHistoryLimit(3) +
  cronJob.mixin.spec.jobTemplate.spec.template.spec.withRestartPolicy('OnFailure') +
  cronJob.mixin.spec.jobTemplate.spec.template.spec.withActiveDeadlineSeconds(600) +
  cronJob.mixin.spec.jobTemplate.spec.withTtlSecondsAfterFinished(120) +
  cronJob.mixin.spec.jobTemplate.spec.template.spec.withVolumes([
    volume.fromConfigMap(
      name='github-readme-scripts',
      configMapName='github-readme-scripts',
    ),
  ]),
]
