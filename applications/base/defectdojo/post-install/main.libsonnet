// jsonnet base/defectdojo/post-install/main.libsonnet -J vendor | yq -o yaml -P '.[] | split_doc' | kubectl apply -f -

local scriptConfig = import 'script-config.libsonnet';

scriptConfig
