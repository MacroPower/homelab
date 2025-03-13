import file

import konfig.models.frontend
import konfig.charts.cilium

import cilium_tenant

app: frontend.App {
    name = "system"
    tenantName = cilium_tenant.tenantConfiguration.name

    charts.cilium = cilium.Chart {
        valueFiles: [
            file.abs(file.current()+"/../values.yaml"),
        ]
    }
}
