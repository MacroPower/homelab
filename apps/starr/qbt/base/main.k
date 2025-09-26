import file

import konfig.models.frontend.secret
import konfig.files

values = files.read_yaml(file.current(), "values.yaml")

oidcClient = secret.ExternalSecret {
    name = "qbt-oidc-client"
    data: {
        "client-id" = {
            remoteRef.key = "STARR_AUTH0_CLIENT_ID"
        }
        "client-secret" = {
            remoteRef.key = "STARR_AUTH0_CLIENT_SECRET"
        }
    }
}
