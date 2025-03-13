import file

import konfig.models.frontend
import konfig.charts.argo_cd

import argo_tenant

app: frontend.App {
    name = "cd"
    tenantName = argo_tenant.tenantConfiguration.name

    charts.argo_cd = argo_cd.Chart {
        valueFiles: [
            file.abs(file.current()+"/../values.yaml"),
        ]
    }
}
