import file
import json

import konfig.models.frontend.configmap
import konfig.files
import konfig.objects

import public_meshcentral_base
import cluster
import charts.meshcentral

_baseValues = public_meshcentral_base.app.charts.meshcentral.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

_meshcentralConfig = public_meshcentral_base.meshcentralConfig | {
    settings: {
        cert = "meshcentral.${cluster.DOMAIN_NAME}"
    }
}

app = public_meshcentral_base.app | {
    domainName = cluster.DOMAIN_NAME
    charts.meshcentral.values = _values

    configMaps.meshcentralConfig = configmap.ConfigMap {
        name = "meshcentral-config"
        data: {
            "config.json" = json.encode(_meshcentralConfig)
        }
    }
}
