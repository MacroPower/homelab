import konfig.models.frontend

import crossplane_shared

app = frontend.App {
    name = "providers"
    tenantName = crossplane_shared.tenant.name
}
