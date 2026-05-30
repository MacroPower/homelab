import json
import file

import k8s.api.core.v1 as corev1

import argo_cd
import bootstrap
import cilium_system_local
import konfig.argocd
import konfig.models.frontend.secret
import konfig.models.metadata as kmd
import kube_csr_approver

_cluster_name = "local"
_argo_cd_namespace = "argo-cd"

# Day-0 bootstrap for the Talos-in-Docker test cluster. Mirrors
# bootstrap/core/mgmt but installs the Docker-safe Cilium overlay and the stock
# (insecure, auth-disabled) Argo CD overlay (apps/argo/cd/local, which also
# injects this cluster's render context as CMP `-D` flags) instead of the
# Auth0/Dragonfly mgmt overlay.
#
# It then deploys the SAME tenant hierarchy as prod (see konfig.argocd). The only
# local-specific knob: the argo-cd overlay's CMP sets `app_env_glob=local`, which
# scopes the `{tenant}-apps` generator to `*/local` overlays, so no per-cluster
# resources are hand-written here.
app = bootstrap.app | {
    extraResources: {
        kube_csr_approver_ns = bootstrap.kube_csr_approver_ns
        cilium_system_ns = bootstrap.cilium_system_ns
        argo_cd_ns = corev1.Namespace {
            metadata.name = _argo_cd_namespace
        }
    }

    charts.kubelet_csr_approver = kube_csr_approver.app.charts.kubelet_csr_approver | {
        namespace = bootstrap.kube_csr_approver_ns.metadata.name
        skipHooks = True
    }

    charts.cilium = cilium_system_local.app.charts.cilium | {
        namespace = bootstrap.cilium_system_ns.metadata.name
    }

    charts.argo_cd = argo_cd.app.charts.argo_cd | {
        namespace = _argo_cd_namespace
    }

    secrets.argo_cd_doppler_credentials = secret.Secret {
        name = "doppler-credentials"
        namespace = _argo_cd_namespace
        stringData = {
            token = file.read_env("DOPPLER_ARGO_CD_TOKEN")
        }
    }

    secrets.local_cluster = secret.Secret {
        name = "{}-cluster".format(_cluster_name)
        namespace = _argo_cd_namespace
        labels = {
            "kubernetes.io/environment" = _cluster_name
            "argocd.argoproj.io/secret-type" = "cluster"
        }
        stringData = {
            name = _cluster_name
            server = "https://kubernetes.default.svc"
            config = json.encode({
                tlsClientConfig = {
                    insecure = True
                }
            })
        }
    }

    # Day-0 GitOps seam, the same shared `bootstrapApp(ctx)` the mgmt hub uses.
    # `env` is pinned to `_cluster_name` here as defense-in-depth: the render
    # context's `env` also arrives via `-D env=local`, but pinning it means a
    # forgotten/typo'd flag still targets the `local` cluster Secret rather than
    # silently aiming the Application at a `mgmt` cluster that does not exist offline.
    extraResources.bootstrapApp = argocd.bootstrapApp(kmd.context | {env = _cluster_name})
}
