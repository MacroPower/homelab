import konfig.models.frontend
import konfig.models.frontend.gateway

tenantConfiguration = frontend.Tenant {
    name = "truenas"
    gateways.default = gateway.Gateway {
        name = "cluster-gateway"
        namespace = "envoy-gateway"
    }
    gateways.public = gateway.Gateway {
        name = "public-gateway"
        namespace = "envoy-gateway"
    }
    oidcIssuer = "https://auth.jacobcolvin.com"
}
