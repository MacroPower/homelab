// jsonnet base/prometheus-stack/main.jsonnet -J vendor --ext-str ingressAnnotations='{}' --ext-str ingressHost='prometheus-stack.example.com'

local ingress = import 'ingress.libsonnet';

ingress
