import json
import file
import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.models.utils
import argo_cd.v1alpha1 as argov1alpha1

_argoCDClusterName = "home"
_argoCDNamespace = "argocd"

appConfiguration: frontend.App {
    secrets.dopplerCredentials = secret.Secret {
        name = "doppler-credentials"
        namespace = _argoCDNamespace
        stringData = {
            token = file.read_env("DOPPLER_TOKEN")
        }
    }

    secrets.localCluster = secret.Secret {
        name = "{}-cluster".format(_argoCDClusterName)
        namespace = _argoCDNamespace
        labels = {
            "kubernetes.io/environment" = _argoCDClusterName
            "argocd.argoproj.io/secret-type" = "cluster"
        }
        stringData = {
            name = _argoCDClusterName
            server = "https://kubernetes.default.svc"
            config = json.encode({
                tlsClientConfig = {
                    insecure = True
                }
            })
        }
    }

    extraResources.appSets = argov1alpha1.Application {
        metadata = utils.AppMetadataBuilder({
            name = "konfig-appsets"
            namespace = _argoCDNamespace
        }, utils.ArgoCDOptions {})
        spec = {
            project = "default"
            source = {
                repoURL = "https://github.com/MacroPower/homelab"
                targetRevision = "konfig"
                path = "konfig/appsets"
                directory.include = "{*.yaml}"
            }
            destination = {
                name = _argoCDClusterName
                namespace = _argoCDNamespace
            }
            syncPolicy = {
                automated = {
                    selfHeal = True
                }
                syncOptions = ["ServerSideApply=true"]
            }
        }
    }
}
