import charts.argo_cd.api.v1alpha1 as argov1alpha1
import models.metadata as kmd
import models.utils
import strings

# tenantsAppSet builds a cluster's top-level `tenants` ApplicationSet: a matrix of
# (clusters labelled `kubernetes.io/environment=<env>` x the tenant bases under
# apps/*/_tenant/base) that creates one Application per tenant, each of which
# renders TenantBackend in-cluster for the selected cluster.
#
# `env` selects the target cluster environment; `ctx` supplies the
# repoURL/revision the generated Applications source from. Called from both
# `appsets/` (env="mgmt", GitHub) and `bootstrap/core/local` (env="local", the
# git mirror), so the two never drift.
tenantsAppSet = lambda env: str, ctx: kmd.RenderContext -> argov1alpha1.ApplicationSet {
    _ns = "argo-cd"
    argov1alpha1.ApplicationSet {
        metadata = utils.AppMetadataBuilder({
            name = "tenants"
            namespace = _ns
        }, utils.ArgoCDOptions {
            compare.ServerSideDiff = True
            compare.IncludeMutationWebhook = True
        })
        spec = {
            goTemplate = True
            goTemplateOptions = ["missingkey=error"]
            # https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Matrix/
            generators = [{
                matrix.generators = [
                    # https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Cluster/
                    {
                        clusters: {
                            selector.matchLabels = {
                                "kubernetes.io/environment" = env
                                "argocd.argoproj.io/secret-type" = "cluster"
                            }
                            values.clusterName = "{{.name}}"
                        }
                    }
                    # https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Git/
                    {
                        git: {
                            repoURL = ctx.repoURL
                            revision = ctx.revision
                            files = [{
                                path = "apps/*/_tenant/base/.tenant.yaml"
                            }]
                            pathParamPrefix = "app"
                        }
                    }
                ]
            }]
            template.metadata = utils.AppMetadataBuilder({
                name = "{{index .app.path.segments 1}}"
                labels.tenant = "{{index .app.path.segments 1}}"
            }, utils.ArgoCDOptions {
                compare.ServerSideDiff = True
                compare.IncludeMutationWebhook = True
                finalize = True
            })
            template.spec = {
                project = "default"
                source = {
                    repoURL = ctx.repoURL
                    targetRevision = ctx.revision
                    path = "{{.app.path.path}}"
                }
                destination = {
                    name = "{{.values.clusterName}}"
                    namespace = _ns
                }
                syncPolicy = {
                    syncOptions = [
                        "ServerSideApply=true"
                        "FailOnSharedResource=true"
                    ]
                    retry = {
                        limit = 5
                        backoff = {
                            duration = "15s"
                            factor = 2
                            maxDuration = "5m"
                        }
                    }
                }
            }
            templatePatch = strings.dedent("""\
                spec:
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
}
