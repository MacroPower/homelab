local resources = [
    import 'goldilocks/kustomization.jsonnet'
];

local merge(resource) = {
    local metadata = resource.metadata,
    local spec = resource.spec,
    resources+: {
        metadata+: metadata {
            namespace: 'argocd',
        },
        spec+: spec {
            destination+: {
                server: 'https://kubernetes.default.svc',
            },
            sources: [
                source
                for source in spec.sources
                if source.repoURL != ''
            ] + [
                source {
                    repoURL: 'https://github.com/MacroPower/homelab',
                    targetRevision: 'argo-apps',
                }
                for source in spec.sources
                if source.repoURL == ''
            ],
        }
    }
};

[
    if resource.kind == 'Application'
    then resource + merge(resource).resources
    else resource
    for resource in resources
]
