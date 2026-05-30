import konfig.argocd
import konfig.models.metadata as kmd
import manifests

# The `tenants` ApplicationSet, built from the shared konfig `tenantsAppSet`
# builder for whatever cluster renders this package. Argo CD's `bootstrap`
# Application renders it through the kclipper CMP, the same way every other app is
# rendered; the CMP injects this cluster's render context, so `ctx.env` is the
# cluster's environment (the prod hub defaults to "mgmt", the local harness's CMP
# sets `-D env=local`). One package, one builder, both clusters -- so the prod and
# local `tenants` appsets cannot drift.
manifests.yaml_stream([argocd.tenantsAppSet(kmd.context.env, kmd.context)])
