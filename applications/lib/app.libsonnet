{
  new(name, path, namespace, project='default'):: {
    local this = self,

    apiVersion: 'argoproj.io/v1alpha1',
    kind: 'Application',
    metadata: {
      name: name,
    },
    spec: {
      project: project,
      sources: [],
      destination: {
        namespace: namespace,
      },
      syncPolicy: {
        automated: {
          prune: true,
          selfHeal: true,
        },
      },
    },

    extVars:: {},
    extVarsMixin:: {},

    withChart(name, repoURL, targetRevision, releaseName='', values=''):: self {
      spec+: {
        sources+: [{
          chart: name,
          repoURL: repoURL,
          targetRevision: targetRevision,
          helm: {
            [if releaseName != '' then 'releaseName']: releaseName,
            [if values != '' then 'valueFiles']: [
              '$base/%(path)s/%(values)s' % {
                path: path,
                values: values,
              },
            ],
          },
        }],
      },
    },

    getExtVars():: [
      {
        name: k,
        value: this.extVars[k],
      }
      for k in std.objectFields(this.extVars)
      if !std.objectHas(this.extVarsMixin, k)
    ] + [
      {
        name: k,
        value: this.extVarsMixin[k],
      }
      for k in std.objectFields(this.extVarsMixin)
    ],

    withBase(repoURL, targetRevision='HEAD', jsonnetLibs=['applications/vendor', 'applications/lib']):: self {
      spec+: {
        sources+: [{
          ref: 'base',
          repoURL: repoURL,
          path: path,
          targetRevision: targetRevision,
          directory: {
            jsonnet: {
              extVars: this.getExtVars(),
              libs: jsonnetLibs,
            },
          },
        }],
      },
    },

    withSource(source):: self {
      spec+: {
        sources+: [source],
      },
    },

    withExtVarsMixin(extVars):: self {
      extVarsMixin+:: extVars,
    },

    withExtVars(extVars):: self {
      extVars+:: extVars,
    },

    withDestinationServer(destinationServer='https://kubernetes.default.svc'):: self {
      spec+: {
        destination+: {
          server: destinationServer,
        },
      },
    },

    withAppNamespace(namespace='argocd'):: self {
      metadata+: {
        namespace: namespace,
      },
    },
  },
}
