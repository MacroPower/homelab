{
  from(app):: app {
    local metadata = app.metadata,
    local spec = app.spec,

    withNamespace(namespace='argocd'):: self {
      metadata+: {
        namespace: namespace,
      },
    },

    withRepo(repoURL='https://github.com/MacroPower/homelab', targetRevision='HEAD'):: self {
      spec+: {
        sources: [
          source
          for source in spec.sources
          if source.repoURL != ''
        ] + [
          source {
            repoURL: repoURL,
            targetRevision: targetRevision,
          }
          for source in spec.sources
          if source.repoURL == ''
        ],
      },
    },

    withDestinationServer(destinationServer='https://kubernetes.default.svc'):: self {
      spec+: {
        destination+: {
          server: destinationServer,
        },
      },
    },

    withExtVars(extVars):: self {
      spec+: {
        sources: [
          source
          for source in spec.sources
          if source.repoURL != ''
        ] + [
          source {
            directory+: {
              jsonnet+: {
                extVars+: [
                  {
                    name: k,
                    value: extVars[k],
                  }
                  for k in std.objectFields(extVars)
                ],
              },
            },
          }
          for source in spec.sources
          if std.objectHas(source, 'directory') && std.objectHas(source.directory, 'jsonnet')
        ],
      },
    },
  },
}
