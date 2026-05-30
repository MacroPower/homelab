import charts.argo_cd.api.v1alpha1 as argov1alpha1
import models.metadata as kmd
import models.utils

# bootstrapApp builds a cluster's day-0 `bootstrap` Argo Application: the
# self-referential GitOps seam that points at the `appsets/` package and lets
# Argo CD manage the top-level `tenants` ApplicationSet from git, the same way
# every other app is managed. The day-0 bundle applies this one Application; the
# application-controller then syncs it, rendering `appsets/` in-cluster through
# the kclipper CMP (which injects this cluster's render context) into the
# `tenants` ApplicationSet, which in turn generates the per-tenant Applications.
#
# `ctx.repoURL`/`ctx.revision` are the source the Application tracks; `ctx.env`
# doubles as its `destination.name` (the registered cluster Secret to deploy to).
# Every field defaults to the prod hub, so `bootstrapApp(kmd.context)` with no
# `-D` reproduces the mgmt hub; the local harness passes `env=local` and the
# git-mirror context, so the two never drift.
bootstrapApp = lambda ctx: kmd.RenderContext -> argov1alpha1.Application {
    _ns = "argo-cd"
    argov1alpha1.Application {
        metadata = utils.AppMetadataBuilder({
            name = "bootstrap"
            namespace = _ns
        }, utils.ArgoCDOptions {
            compare.ServerSideDiff = True
            compare.IncludeMutationWebhook = True
            finalize = False
        })
        spec = {
            project = "default"
            source = {
                repoURL = ctx.repoURL
                targetRevision = ctx.revision
                # A bare source (no `directory`/`plugin`) lets Argo CD's CMP
                # discovery pick the kcl plugin via its `*.k` discover rule, so
                # `appsets/` renders the `tenants` ApplicationSet in-cluster.
                path = "appsets"
            }
            destination = {
                name = ctx.env
                namespace = _ns
            }
            syncPolicy = {
                automated = {
                    selfHeal = True
                }
                syncOptions = ["ServerSideApply=true"]
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
    }
}
