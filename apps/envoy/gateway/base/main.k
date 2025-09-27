import file

import konfig.models.frontend
import konfig.files

import envoy
import charts.envoy_gateway
import charts.envoy_gateway.api.v1 as gatewayv1
import charts.envoy_gateway.api.v1alpha1 as gatewayv1alpha1
import charts.cert_manager.api.v1 as certmanagerv1

_values = files.read_yaml(file.current(), "values.yaml")

_gp = gatewayv1alpha1.EnvoyProxy {
    metadata.name = "envoy-proxy"
    spec: {
        provider: {
            type = "Kubernetes"
            kubernetes = {
                envoyDeployment = {
                    replicas = 2
                    container.resources = {
                        requests = {
                            cpu = "100m"
                            memory = "128Mi"
                        }
                        limits = {
                            memory = "256Mi"
                        }
                    }
                }
                envoyService = {
                    type = "LoadBalancer"
                    externalTrafficPolicy = "Cluster"
                    labels = {
                        "bgp.kube.macro.network/peer-group" = "main"
                    }
                }
            }
        }
    }
}

_gwc = gatewayv1.GatewayClass {
    metadata.name = "envoy-gateway"
    spec: {
        controllerName = "gateway.envoyproxy.io/gatewayclass-controller"
    }
}

_clusterGateway = gatewayv1.Gateway {
    metadata.name = "cluster-gateway"
    spec: {
        gatewayClassName = "envoy-gateway"
        infrastructure = {
            parametersRef = {
                group = "gateway.envoyproxy.io"
                kind = "EnvoyProxy"
                name = "envoy-proxy"
            }
        }
        listeners = [
            {
                name = "http"
                protocol = "HTTP"
                port = 80
                allowedRoutes.namespaces.from = "Same"
            }
            {
                name = "https"
                protocol = "HTTPS"
                port = 443
                allowedRoutes.namespaces.from = "All"
                tls.certificateRefs = [
                    {
                        kind = "Secret"
                        name = "cluster-wildcard"
                    }
                ]
            }
        ]
    }
}

_publicGateway = gatewayv1.Gateway {
    metadata.name = "public-gateway"
    spec: {
        gatewayClassName = "envoy-gateway"
        infrastructure = {
            parametersRef = {
                group = "gateway.envoyproxy.io"
                kind = "EnvoyProxy"
                name = "envoy-proxy"
            }
        }
        listeners = [
            {
                name = "http"
                protocol = "HTTP"
                port = 80
                allowedRoutes.namespaces.from = "Same"
            }
            {
                name = "https"
                protocol = "HTTPS"
                port = 443
                allowedRoutes.namespaces.from = "All"
                tls.certificateRefs = [
                    {
                        kind = "Secret"
                        name = "public-wildcard"
                    }
                ]
            }
        ]
    }
}

app = frontend.App {
    name = "gateway"
    tenantName = envoy.tenant.name

    charts.envoy_gateway = envoy_gateway.Chart {
        values: _values | envoy_gateway.Values {}
    }

    extraResources: {
        proxy = _gp
        gatewayClass = _gwc
        clusterGateway = _clusterGateway
        publicGateway = _publicGateway
    }

    extraResources.envoyPublicGatewayCertificate = certmanagerv1.Certificate {
        metadata.name = "public-wildcard"
        spec: {
            dnsNames = [
                "jacobcolvin.com"
                "*.jacobcolvin.com"
            ]
            secretName = "public-wildcard"
            issuerRef: {
                kind = "ClusterIssuer"
                name = "cloudflare-jacobcolvin-com-issuer"
            }
        }
    }
}
