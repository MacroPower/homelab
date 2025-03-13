import file
import json

import argo_cd_base
import filepath
import konfig.models.frontend.secret

_current_dir = filepath.dir(file.current())

secretStoreClusters = secret.SecretStore {
    name = "clusters"
    provider.doppler.auth.secretRef.dopplerToken = {
        name = "doppler-credentials"
        key = "token"
    }
}

app = argo_cd_base.app | {
    secretStores.clusters = secretStoreClusters

    charts.argo_cd.valueFiles += [
        filepath.join([_current_dir, "values.yaml"]),
    ]

    externalSecrets.nas01 = secret.ExternalSecret {
        name = "nas01-credentials"
        secretStoreRef = secretStoreClusters.getRef()
        data = {
            NAS01_API_SERVER = {}
            NAS01_CA_DATA = {}
            NAS01_CERT_DATA = {}
            NAS01_KEY_DATA = {}
        }
        target.template.metadata.labels = {
            "kubernetes.io/environment" = "nas01"
            "argocd.argoproj.io/secret-type" = "cluster"
        }
        target.template.data = {
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
}
