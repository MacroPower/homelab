{
  new(name, path, namespace, project='default', renderer='jsonnet'):: {
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

    basePath:: path,
    extVars:: {},
    extVarsMixin:: {},
    sourceMixin:: [],

    withChartParams(params={}):: self {
      spec+: {
        sources: [
          source {
            helm+: {
              parameters: [
                {
                  name: k,
                  value: params[k],
                }
                for k in std.objectFields(params)
              ],
            },
          }
          for source in this.spec.sources
          if std.objectHas(source, 'chart')
        ] + [
          source
          for source in this.spec.sources
          if !std.objectHas(source, 'chart')
        ],
      },
    },

    withChartValues(values=''):: self {
      spec+: {
        sources: [
          source {
            helm+: {
              values: values,
            },
          }
          for source in this.spec.sources
          if std.objectHas(source, 'chart')
        ] + [
          source
          for source in this.spec.sources
          if !std.objectHas(source, 'chart')
        ],
      },
    },

    withChart(name, repoURL, targetRevision, releaseName='', values='', skipCrds=false):: self {
      spec+: {
        sources+: [{
          chart: name,
          repoURL: repoURL,
          targetRevision: targetRevision,
          helm: {
            [if releaseName != '' then 'releaseName']: releaseName,
            [if skipCrds then 'skipCrds']: true,
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
      local directory =
        if renderer == 'jsonnet' then {
          directory: {
            include: '*.jsonnet',
            jsonnet: {
              extVars: this.getExtVars(),
              libs: jsonnetLibs,
            },
          },
        } else {
        },
      spec+: {
        sources+: [
          {
            ref: 'base',
            repoURL: repoURL,
            path: this.basePath,
            targetRevision: targetRevision,
          } + directory,
        ] + [
          {
            repoURL: repoURL,
            path: path,
            targetRevision: targetRevision,
          } + directory
          for path in this.sourceMixin
        ],
      },
    },

    withBasePath(path):: self {
      basePath:: path,
    },

    withSourceMixin(path):: self {
      sourceMixin+:: [path],
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
