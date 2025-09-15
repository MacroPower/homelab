import konfig.models.frontend
import konfig.models.frontend.gateway

tenantConfiguration = frontend.Tenant {
    name = "public"
    gateways.default = gateway.Gateway {
        name = "cluster-gateway"
        namespace = "envoy-gateway"
    }
    oidcIssuer = "https://auth.jacobcolvin.com"
}
