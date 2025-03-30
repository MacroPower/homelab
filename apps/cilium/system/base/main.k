import file

import charts.cilium
import cilium_shared
import konfig.models.frontend
import konfig.utils

_valueFile = utils.abs_path(file.current(), "values.yaml")

app: frontend.App {
    name = "system"
    tenantName = cilium_shared.tenant.name

    charts.cilium = cilium.Chart {
        valueFiles: [_valueFile]
    }
}
