import charts.argo_cd.api.v1alpha1 as argov1alpha1
import models.frontend
import models.mixins
import models.metadata as kmd
import models.resource
import models.utils
import utils as kutils

schema TenantBackend[inputConfig: frontend.Tenant]:
    """
    TenantBackend converts the user-written front-end model `Tenant` into a
    collection of k8s resources and places the resource collection into
    the `k8s` attribute.
    """
    # mixin [
    #     # Resource builder mixin
    #     mixins.ClusterSecretStoreMixin
    # ]
    # Store the input config parameter, ensure it can be seen in protocol and mixin.
    config: frontend.Tenant = inputConfig

    _metadata = config | {
        labels = {
            tenant = config.name
        }
    }

    _argoSharedAppProject: argov1alpha1.AppProject {
        metadata = utils.MetadataBuilder(_metadata | {
            name = "${config.name}-shared"
        })
        spec: {
            sourceNamespaces: ["{}-*".format(config.name)]
            sourceRepos: ["*"]
            destinations: [{
                namespace = "*"
                server = "*"
            }]
            clusterResourceWhitelist: [{
                group = "*"
                kind = "*"
            }]
            namespaceResourceWhitelist: [{
                group = "*"
                kind = "*"
            }]
        }
    }

    _argoSharedApplicationSet: argov1alpha1.ApplicationSet {
        metadata = utils.AppMetadataBuilder(_metadata | {
            name = "${config.name}-shared"
        }, utils.ArgoCDOptions {
            sync.Prune = "false"
            finalize = False
        })
        spec: {
            generators = [{
                matrix.generators = [
                    {
                        git: {
                            repoURL = kmd.__META_REPO_URL
                            revision = kmd.__META_REVISION
                            files = [{
                                path = "apps/${config.name}/_tenant/shared/.tenant.yaml"
                            }]
                            pathParamPrefix = "tenant"
                        }
                    }
                    {
                        merge.mergeKeys = ["values.cluster"]
                        merge.generators = [
                            {
                                git: {
                                    repoURL = kmd.__META_REPO_URL
                                    revision = kmd.__META_REVISION
                                    files = [{
                                        path = "apps/${config.name}/*/*/.app.yaml"
                                    }]
                                    pathParamPrefix = "app"
                                    values = {
                                        cluster = "{{index .app.path.segments 3}}"
                                    }
                                }
                            }
                        ]
                    }
                ]
            }]
            template.metadata: utils.AppMetadataBuilder(_metadata | {
                name = "${config.name}-{{.values.cluster}}"
            }, utils.ArgoCDOptions {
                compare.ServerSideDiff = True
                compare.IncludeMutationWebhook = True
                sync.Prune = "confirm"
            })
            template.spec: {
                project = "${config.name}-shared"
                source: {
                    repoURL = kmd.__META_REPO_URL
                    targetRevision = kmd.__META_REVISION
                    path = "{{.tenant.path.path}}"
                }
                destination: {
                    name = "{{.values.cluster}}"
                    namespace = "default" # This appset should only deploy cluster resources.
                }
                syncPolicy: {
                    syncOptions = [
                        "ServerSideApply=true"
                        "FailOnSharedResource=true"
                    ]
                    retry: {
                        limit = 5
                        backoff: {
                            duration = "15s"
                            factor = 2
                            maxDuration = "5m"
                        }
                    }
                }
            }
            templatePatch = kutils.dedent("""\
                spec:
                  {{- with (index . "source") }}
                  source:
                    targetRevision: {{ .targetRevision | quote }}
                  {{- end }}
                  {{- with (index . "syncPolicy") }}
                  syncPolicy:
                    automated:
                      {{ toYaml .automated | nindent 6 }}
                  {{- end }}
                  {{- with (index . "ignoreDifferences") }}
                  ignoreDifferences:
                    {{ toYaml . | nindent 4 }}
                  {{- end }}
            """)
        }
    }

    _argoAppProject: argov1alpha1.AppProject {
        metadata = utils.MetadataBuilder(_metadata | {
            name = "${config.name}-apps"
        })
        spec: {
            sourceNamespaces: ["{}-*".format(config.name)]
            sourceRepos: ["*"]
            destinations: [{
                namespace = "{}-*".format(config.name)
                server = "*"
            }]
            clusterResourceWhitelist: [{
                group = "*"
                kind = "*"
            }]
            namespaceResourceWhitelist: [{
                group = "*"
                kind = "*"
            }]
        }
    }

    _argoApplicationSet: argov1alpha1.ApplicationSet {
        metadata = utils.AppMetadataBuilder(_metadata | {
            name = "${config.name}-apps"
        }, utils.ArgoCDOptions {
            sync.Prune = "false"
            finalize = False
        })
        spec: {
            goTemplate = True
            goTemplateOptions = ["missingkey=error"]
            generators = [{
                git: {
                    repoURL = kmd.__META_REPO_URL
                    revision = kmd.__META_REVISION
                    files = [{
                        path = "apps/${config.name}/*/*/.app.yaml"
                    }]
                    pathParamPrefix = "app"
                }
            }]
            template.metadata: utils.AppMetadataBuilder(_metadata | {
                name = "${config.name}-{{index .app.path.segments 2}}-{{.app.path.basename}}"
                labels: {
                    app = "${config.name}-{{index .app.path.segments 2}}"
                }
            }, utils.ArgoCDOptions {
                compare.ServerSideDiff = True
                compare.IncludeMutationWebhook = True
                sync.Prune = "confirm"
            })
            template.spec: {
                project = "${config.name}-apps"
                source: {
                    repoURL = kmd.__META_REPO_URL
                    targetRevision = kmd.__META_REVISION
                    path = "{{.app.path.path}}"
                }
                destination: {
                    name = "{{.app.path.basename}}"
                    namespace = "${config.name}-{{index .app.path.segments 2}}"
                }
                syncPolicy: {
                    managedNamespaceMetadata: {
                        labels: _metadata.labels | {
                            app = "${config.name}-{{index .app.path.segments 2}}"
                        }
                    }
                    syncOptions = [
                        "ServerSideApply=true"
                        "CreateNamespace=true"
                        "FailOnSharedResource=true"
                    ]
                    retry: {
                        limit = 5
                        backoff: {
                            duration = "15s"
                            factor = 2
                            maxDuration = "5m"
                        }
                    }
                }
            }
            templatePatch = kutils.dedent("""\
                spec:
                  {{- with (index . "source") }}
                  source:
                    targetRevision: {{ .targetRevision | quote }}
                  {{- end }}
                  {{- with (index . "syncPolicy") }}
                  syncPolicy:
                    automated:
                      {{ toYaml .automated | nindent 6 }}
                  {{- end }}
                  {{- with (index . "ignoreDifferences") }}
                  ignoreDifferences:
                    {{ toYaml . | nindent 4 }}
                  {{- end }}
            """)
        }
    }
    kubernetes: resource.ResourceMapping = {
        if _argoAppProject:
            "${typeof(_argoAppProject)}" = [
                _argoSharedAppProject
                _argoAppProject
            ]
        if _argoApplicationSet:
            "${typeof(_argoApplicationSet)}" = [
                _argoSharedApplicationSet
                _argoApplicationSet
            ]
    }
