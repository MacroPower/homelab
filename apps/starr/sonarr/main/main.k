import file

import konfig.models.frontend.ingress
import konfig.files
import konfig.objects

import starr_sonarr_base
import cluster
import charts.sonarr

_baseValues = starr_sonarr_base.app.charts.sonarr.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

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
