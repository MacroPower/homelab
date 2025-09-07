import file

import konfig.models.frontend.ingress
import konfig.files
import konfig.objects

import cluster
import starr_prowlarr_base
import charts.prowlarr

_baseValues = starr_prowlarr_base.app.charts.prowlarr.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = starr_prowlarr_base.app | {
    domainName = cluster.DOMAIN_NAME
    charts.prowlarr.values = _values | prowlarr.Values {}
    ingresses.main = ingress.Ingress {
        className = "cilium"
        rules.main = {
            host.name = "prowlarr"
            httpPaths.main.backend.service = {
                name = "prowlarr"
                port.name = "http"
            }
        }
    }
}
