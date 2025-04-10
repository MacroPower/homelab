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
        "${_redisSecretKey}" = {
            sourceRef.generatorRef = {
                name = "alphanumeric-password"
            }
        }
    }
}

_nas01Creds = secret.ExternalSecret {
    name = "nas01-credentials"
    secretStoreRef = _secretStoreClusters.getRef()
    data: {
        NAS01_API_SERVER = {}
        NAS01_CA_DATA = {}
        NAS01_CERT_DATA = {}
        NAS01_KEY_DATA = {}
    }
    target.template.metadata.labels: {
        "kubernetes.io/environment" = "nas01"
        "argocd.argoproj.io/secret-type" = "cluster"
    }
    target.template.data: {
        name = "nas01"
        server = "{{ .NAS01_API_SERVER }}"
        config = json.encode({
            tlsClientConfig = {
                insecure = True
                certData = "{{ .NAS01_CERT_DATA }}"
                keyData = "{{ .NAS01_KEY_DATA }}"
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
                username = "default"
                existingSecret = _argoCreds.name
            }
        }
    }
    externalSecrets: {
        nas01 = _nas01Creds
        argocd = _argoCreds
    }
    extraResources: {
        redis = _dragonfly
    }
    ingresses.main = ingress.Ingress {
        rules.main = {
            httpPaths.main.backend.service = {
                name = "argo-cd-server"
                port.name = "http"
            }
        }
    }
}
