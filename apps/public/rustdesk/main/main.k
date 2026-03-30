import file

import konfig.files
import konfig.objects

import public_rustdesk_base
import charts.rustdesk

_baseValues = public_rustdesk_base.app.charts.rustdesk.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = public_rustdesk_base.app | {
    domainName = "jacobcolvin.com"
    charts.rustdesk.values = _values

    routes.rustdeskWeb.gatewayRef = {
        name = "public-gateway"
        namespace = "envoy-gateway"
    }
}
