import json
import file

import k8s.api.core.v1 as corev1

import argo_cd
import bootstrap
import cilium_system
import konfig.argocd
import konfig.models.frontend.secret
import konfig.models.metadata as kmd
import kube_csr_approver

_cluster_name = "mgmt"
_argo_cd_namespace = "argo-cd"

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

    charts.cilium = cilium_system.app.charts.cilium | {
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

    # Day-0 GitOps seam (see konfig.argocd.bootstrapApp); `kmd.context` defaults
    # to this hub (env=mgmt, GitHub repo/main).
    extraResources.bootstrapApp = argocd.bootstrapApp(kmd.context)
}
