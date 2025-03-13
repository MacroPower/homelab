import file

import charts.cilium
import cilium_tenant
import filepath
import konfig.models.frontend

_current_dir = filepath.dir(file.current())

app: frontend.App {
    name = "system"
    tenantName = cilium_tenant.tenantConfiguration.name

    charts.cilium = cilium.Chart {
        valueFiles: [
            filepath.join([_current_dir, "values.yaml"]),
        ]
    }
}
