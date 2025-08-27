import file
import json

import argo_cd_base
import cluster
import charts.argo_cd
import charts.dragonfly_operator.api.v1alpha1 as dragonflyv1alpha1
import konfig.models.frontend.secret
import konfig.models.frontend.ingress
import konfig.utils

_baseValues = argo_cd_base.app.charts.argo_cd.values
_envValues = utils.read_yaml(file.current(), "values.yaml")
_values = utils.json_merge_patch(_baseValues, _envValues)

_namespace = argo_cd_base.app.namespace
_dragonflyName = "argocd-redis-dragonfly"
_redisSecretKey = "redis-password"

_secretStoreClusters = secret.SecretStore {
    name = "clusters"
    provider.doppler.auth.secretRef.dopplerToken = {
        name = "doppler-credentials"
        key = "token"
    }
}

_argoCreds = secret.ExternalSecret {
    name = "argocd-credentials"
    refreshInterval = "0"
    data: {
        REDIS_PASSWORD = {
            sourceRef.generatorRef = {
                name = "alphanumeric-password"
            }
        }
    }
    target.template.data: {
        "redis-username" = "default"
        "${_redisSecretKey}" = "{{ .REDIS_PASSWORD }}"
    }
}

_mainCreds = secret.ExternalSecret {
    name = "main-credentials"
    secretStoreRef = _secretStoreClusters.getRef()
    data: {
        MAIN_API_SERVER = {}
        MAIN_CA_DATA = {}
        MAIN_CERT_DATA = {}
        MAIN_KEY_DATA = {}
    }
    target.template.metadata.labels: {
        "kubernetes.io/environment" = "main"
        "argocd.argoproj.io/secret-type" = "cluster"
    }
    target.template.data: {
        name = "main"
        server = "{{ .MAIN_API_SERVER }}"
        config = json.encode({
            tlsClientConfig = {
                insecure = True
                certData = "{{ .MAIN_CERT_DATA }}"
                keyData = "{{ .MAIN_KEY_DATA }}"
            }
        })
    }
}

_dragonfly = dragonflyv1alpha1.Dragonfly {
    metadata: {
        name = _dragonflyName
    }
    spec: {
        replicas = 3
        authentication.passwordFromSecret = {
            name = _argoCreds.name
            key = _redisSecretKey
        }
    }
}

app = argo_cd_base.app | {
    domainName = cluster.DOMAIN_NAME
    secretStores: {
        clusters = _secretStoreClusters
    }
    charts: {
        argo_cd.values = _values | argo_cd.Values {
            redis.enabled = False
            externalRedis: {
                host = "${_dragonflyName}.${_namespace}.svc.cluster.local"
                port = 6379
                existingSecret = _argoCreds.name
            }
        }
    }
    externalSecrets: {
        main = _mainCreds
        argocd = _argoCreds
    }
    extraResources: {
        redis = _dragonfly
    }
    ingresses.main = ingress.Ingress {
        className = "cilium"
        rules.main = {
            httpPaths.main.backend.service = {
                name = "argo-cd-server"
                port.name = "http"
            }
        }
    }
}
