local app = std.parseYaml(importstr '../../../base/goldilocks/application.yaml');

local merge(resource) = {
    local spec = resource.spec,
    resources+: {
        spec+: spec {
            sources: [
                source
                for source in spec.sources
                if source.repoURL != ''
            ] + [
                source {
                    directory: {
                        jsonnet: {
                            extVars: [
                                {
                                    name: 'ingressAnnotations',
                                    value: |||
                                        'kubernetes.io/ingress.class': 'traefik'
                                    |||,
                                },
                                {
                                    name: 'ingressHost',
                                    value: 'goldilocks.home.macro.network',
                                },
                            ],
                        },
                    },
                }
                for source in spec.sources
                if source.repoURL == ''
            ],
        }
    }
};

app + merge(app).resources
