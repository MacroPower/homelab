import json
import konfig.models.frontend
import konfig.models.frontend.secret
import tenant

tenantConfiguration = tenant.tenantConfiguration

appConfiguration: frontend.App {
    name = "cd"
    tenantName = tenantConfiguration.name
    namespace = "argocd"

    secretStores.clusters = secret.SecretStore {
        name = "clusters"
        provider.doppler.auth.secretRef.dopplerToken = {
            name = "doppler-credentials"
            key = "token"
        }
    }

    externalSecrets.nas01 = secret.ExternalSecret {
        name = "nas01-credentials"
        secretStoreRef = secretStores.clusters.getRef()
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
