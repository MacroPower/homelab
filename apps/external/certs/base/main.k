import file

import charts.cert_manager
import charts.cert_manager.api.v1 as certmanagerv1
import external
import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.utils

_values = utils.read_yaml(file.current(), "values.yaml")

_cloudflareCreds = secret.ExternalSecret {
    name = "cloudflare-credentials"
    data = {
        CLOUDFLARE_API_TOKEN = {}
    }
}

_cloudflareCA = certmanagerv1.ClusterIssuer {
    metadata.name = "cloudflare-issuer"
    spec.acme: {
        email = "null@macro.network"
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
            name = "cloudflare-issuer-account-key"
        }
        solvers = [
            {
                dns01.cloudflare = {
                    apiTokenSecretRef = {
                        name = "cloudflare-credentials"
                        key = "CLOUDFLARE_API_TOKEN"
                    }
                }
            }
        ]
    }
}

app: frontend.App {
    name = "certs"
    tenantName = external.tenant.name
    secretStore = external.shared.secretStores.default.name
    namespace = "{}-{}".format(tenantName, name)

    externalSecrets.cloudflareCreds = _cloudflareCreds
    extraResources.cloudflareCA = _cloudflareCA

    charts.cert_manager = cert_manager.Chart {
        values: _values | cert_manager.Values {
            global: {
                leaderElection.namespace = namespace
            }
        }
    }
}
