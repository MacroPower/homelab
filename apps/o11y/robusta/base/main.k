import file

import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.files

import o11y
import charts.robusta

_values = files.read_yaml(file.current(), "values.yaml")

_config = secret.ExternalSecret {
    name = "robusta-config"
    data: {
        ROBUSTA_SIGNING_KEY = {}
        ROBUSTA_ACCOUNT_ID = {}
        ROBUSTA_UI_SINK_TOKEN = {}
    }
}

app = frontend.App {
    name = "robusta"
    tenantName = o11y.tenant.name

    secretStore = o11y.shared.secretStores.default.name

    charts.robusta = robusta.Chart {
        values: _values | robusta.Values {}
    }

    externalSecrets.robustaConfig = _config
}
