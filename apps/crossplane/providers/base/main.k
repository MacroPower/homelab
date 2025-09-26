import konfig.models.frontend

import crossplane

app = frontend.App {
    name = "providers"
    tenantName = crossplane.tenant.name
}
