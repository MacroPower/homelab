import file

import starr
import charts.sonarr
import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.utils

_values = utils.read_yaml(file.current(), "values.yaml")

_sonarrCreds = secret.ExternalSecret {
    name = "sonarr-credentials"
    data: {
        SONARR_AUTH_APIKEY = {}
        SONARR_POSTGRES_PASSWORD = {}
    }
}

app = frontend.App {
    name = "sonarr"
    tenantName = starr.tenant.name

    secretStore = starr.shared.secretStores.default.name
    externalSecrets.sonarrCreds = _sonarrCreds

    charts.sonarr = sonarr.Chart {
        values: _values | sonarr.Values {}
    }
}
