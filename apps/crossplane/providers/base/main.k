import konfig.models.frontend
import charts.crossplane.api.v1 as crossplanev1

import crossplane_shared

app = frontend.App {
    name = "providers"
    tenantName = crossplane_shared.tenant.name

    extraResources.terraformProvider = crossplanev1.Provider {
        metadata.name = "upbound-provider-opentofu"
        spec.package = "xpkg.upbound.io/upbound/provider-opentofu:v1.1.1"
    }
}
