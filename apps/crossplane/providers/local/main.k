import crossplane_providers_base
import charts.crossplane.api.v1 as crossplanev1

# Non-chart raw konfig app. Mirror main verbatim: it only adds a single
# crossplane Provider CR via extraResources. Renders offline; runtime needs the
# crossplane/system Provider CRD installed plus internet access to pull the
# provider package from xpkg.upbound.io.
app = crossplane_providers_base.app | {
    extraResources.terraformProvider = crossplanev1.Provider {
        metadata.name = "upbound-provider-opentofu"
        spec.package = "xpkg.upbound.io/upbound/provider-opentofu:v1.1.1"
    }
}
