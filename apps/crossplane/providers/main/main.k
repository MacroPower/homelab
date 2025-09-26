import crossplane_providers_base
import charts.crossplane.api.v1 as crossplanev1

app = crossplane_providers_base.app | {
    extraResources.terraformProvider = crossplanev1.Provider {
        metadata.name = "upbound-provider-opentofu"
        spec.package = "xpkg.upbound.io/upbound/provider-opentofu:v1"
    }
}
