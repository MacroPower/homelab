import file

import starr_sonarr_base
import cluster
import charts.sonarr
import konfig.models.frontend.ingress
import konfig.utils

_baseValues = starr_sonarr_base.app.charts.sonarr.values
_envValues = utils.read_yaml(file.current(), "values.yaml")
_values = utils.json_merge_patch(_baseValues, _envValues)

app = starr_sonarr_base.app | {
    domainName = cluster.DOMAIN_NAME
    charts.sonarr.values = _values | sonarr.Values {}
    ingresses.main = ingress.Ingress {
        className = "cilium"
        rules.main = {
            host.name = "sonarr"
            httpPaths.main.backend.service = {
                name = "sonarr"
                port.name = "http"
            }
        }
    }
}
