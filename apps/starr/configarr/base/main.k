import file
import yaml

import konfig.models.frontend
import konfig.models.frontend.configmap
import konfig.models.frontend.secret
import konfig.files

import starr
import charts.configarr

_values = files.read_yaml(file.current(), "values.yaml")

_config = configmap.ConfigMap {
    name = "configarr"
    data: {
        "config.yml" = files.read_file(file.current(), "config.yaml")
    }
}

_secrets = secret.ExternalSecret {
    name = "configarr"
    data: {
        SONARR_AUTH_APIKEY = {}
        RADARR_AUTH_APIKEY = {}
    }
}

app = frontend.App {
    name = "configarr"
    tenantName = starr.tenant.name
    secretStore = starr.shared.secretStores.default.name

    configMaps.configarr = _config
    externalSecrets.configarr = _secrets

    charts.configarr = configarr.Chart {
        values: _values | configarr.Values {}
    }
}
