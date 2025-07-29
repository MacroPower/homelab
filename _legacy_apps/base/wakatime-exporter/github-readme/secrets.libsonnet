local external_secret = import '../../../lib/external_secret.libsonnet';
local ns = import '../namespace.libsonnet';

[
  external_secret.new(
    name='github-readme-credentials',
    namespace=ns.metadata.name,
    data=[
      external_secret.data(key='WAKATIME_GITHUB_REPO_URL'),
    ]
  ),
]
