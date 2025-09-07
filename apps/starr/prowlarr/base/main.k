import file

import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.files

import starr
import charts.prowlarr

_values = files.read_yaml(file.current(), "values.yaml")

_prowlarrCreds = secret.ExternalSecret {
    name = "prowlarr-credentials"
    data: {
        PROWLARR_AUTH_APIKEY = {}
        PROWLARR_POSTGRES_PASSWORD = {}
    }
}

app = frontend.App {
    name = "prowlarr"
    tenantName = starr.tenant.name

    secretStore = starr.shared.secretStores.default.name
    externalSecrets.prowlarrCreds = _prowlarrCreds

    charts.prowlarr = prowlarr.Chart {
        values: _values | prowlarr.Values {}
    }
}
