import file

import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.files

import external
import charts.cert_manager
import charts.cert_manager.api.v1 as certmanagerv1

_values = files.read_yaml(file.current(), "values.yaml")

_cfMacroNetwork = secret.ExternalSecret {
    name = "cloudflare-macro-network"
    data = {
        API_TOKEN = {
            remoteRef.key = "CLOUDFLARE_MACRO_NETWORK_API_TOKEN"
        }
    }
}

_cfJacobColvinCom = secret.ExternalSecret {
    name = "cloudflare-jacobcolvin-com"
    data = {
        API_TOKEN = {
            remoteRef.key = "CLOUDFLARE_JACOBCOLVIN_COM_API_TOKEN"
        }
    }
}

_cfMacroNetworkCI = certmanagerv1.ClusterIssuer {
    metadata.name = "cloudflare-macro-network-issuer"
    spec.acme: {
        email = "null@macro.network"
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef.name = "cloudflare-issuer-macro-network-key"
        solvers = [{
            dns01.cloudflare.apiTokenSecretRef = _cfMacroNetwork.getSecretKeyRef("API_TOKEN")
        }]
    }
}

_cfJacobColvinComCI = certmanagerv1.ClusterIssuer {
    metadata.name = "cloudflare-jacobcolvin-com-issuer"
    spec.acme: {
        email = "null@jacobcolvin.com"
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef.name = "cloudflare-issuer-jacobcolvin-com-key"
        solvers = [{
            dns01.cloudflare.apiTokenSecretRef = _cfJacobColvinCom.getSecretKeyRef("API_TOKEN")
        }]
    }
}

app = frontend.App {
    name = "certs"
    tenantName = external.tenant.name
    secretStore = external.shared.secretStores.default.name
    namespace = "{}-{}".format(tenantName, name)

    externalSecrets.cfMacroNetwork = _cfMacroNetwork
    extraResources.cfMacroNetworkCI = _cfMacroNetworkCI

    externalSecrets.cfJacobColvinCom = _cfJacobColvinCom
    extraResources.cfJacobColvinComCI = _cfJacobColvinComCI

    charts.cert_manager = cert_manager.Chart {
        values: _values | cert_manager.Values {
            global: {
                leaderElection.namespace = namespace
            }
        }
    }

    extraResources.cloudflarePublicIngress = certmanagerv1.Certificate {
        metadata.name = "public-ingress"
        spec: {
            dnsNames = ["*.jacobcolvin.com"]
            secretName = "public-ingress"
            issuerRef: {
                kind = "ClusterIssuer"
                name = "cloudflare-jacobcolvin-com-issuer"
            }
        }
    }
}
