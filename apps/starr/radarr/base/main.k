import file

import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.files

import starr
import charts.radarr

_values = files.read_yaml(file.current(), "values.yaml")

_radarrCreds = secret.ExternalSecret {
    name = "radarr-credentials"
    data: {
        RADARR_AUTH_APIKEY = {}
        RADARR_POSTGRES_PASSWORD = {}
    }
}

app = frontend.App {
    name = "radarr"
    tenantName = starr.tenant.name

    secretStore = starr.shared.secretStores.default.name
    externalSecrets.radarrCreds = _radarrCreds

    charts.radarr = radarr.Chart {
        values: _values | radarr.Values {}
    }
}
