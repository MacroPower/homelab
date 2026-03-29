import file
import json

import konfig.models.frontend.secret
import konfig.files
import konfig.objects

import public_meshcentral_base
import cluster
import charts.meshcentral

_baseValues = public_meshcentral_base.app.charts.meshcentral.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

_meshcentralOIDCClient = secret.ExternalSecret {
    name = "meshcentral-oidc-config"
    data: {
        "MESHCENTRAL_AUTH0_CLIENT_ID" = {}
        "MESHCENTRAL_AUTH0_CLIENT_SECRET" = {}
    }
    target = {
        name = "meshcentral-config"
        template.data: {
            "config.json" = json.encode(public_meshcentral_base.meshcentralConfig | {
                settings: {
                    cert = "meshcentral.jacobcolvin.com"
                }
                domains: {
                    "": {
                        authStrategies.oidc: {
                            issuer = "https://auth.jacobcolvin.com/"
                            client: {
                                client_id = "{{ .MESHCENTRAL_AUTH0_CLIENT_ID }}"
                                client_secret = "{{ .MESHCENTRAL_AUTH0_CLIENT_SECRET }}"
                                redirect_uri = "https://meshcentral.jacobcolvin.com/auth-oidc-callback"
                            }
                        }
                    }
                }
            })
        }
    }
}

app = public_meshcentral_base.app | {
    domainName = "jacobcolvin.com"
    charts.meshcentral.values = _values

    externalSecrets.meshcentralOIDCClient = _meshcentralOIDCClient
}
