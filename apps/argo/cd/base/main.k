import file

import argo_tenant
import charts.argo_cd
import filepath
import konfig.models.frontend

_current_dir = filepath.dir(file.current())

app: frontend.App {
    name = "cd"
    tenantName = argo_tenant.tenantConfiguration.name

    charts.argo_cd = argo_cd.Chart {
        valueFiles: [
            filepath.join([_current_dir, "values.yaml"]),
        ]
    }
}
