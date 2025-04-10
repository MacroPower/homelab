import models.frontend.common
import k8s.api.networking.v1 as networkingv1

schema Ingress(common.Metadata):
    """
    Ingress is a collection of rules that allow inbound connections to reach the
    endpoints defined by a backend. An Ingress can be configured to give
    services externally-reachable urls, load balance traffic, terminate SSL,
    offer name based virtual hosting etc.

    Attributes
    ----------
    rules: {str:IngressRule}, default is Undefined, optional
        A list of host rules used to configure the Ingress. If unspecified, or
        no rule matches, all traffic is sent to the default backend.

    Examples
    --------
    ingress.Ingress {
        name = "example-ingress"
        rules.main = {
            host = "your-domain.com"
            httpPaths.main = {
                path = "/apple"
                pathType = "Prefix"
                backend.service: {
                    name = "app-service"
                    port.number = 5678
                }
            }
        }
    }
    """
    className?: str
    rules: {str:IngressRule}

schema IngressRule:
    """
    Attributes
    ----------
    host: str, required
    httpPaths: {str:HTTPIngressPath}, required
    tlsSecretName: str, optional
    """
    host?: IngressHost
    httpPaths: {str:HTTPIngressPath}
    tlsSecretName?: str

schema IngressHost:
    """
    Attributes
    ----------
    name: str, optional
        Set the DN.
    fullName: str, optional
        Set the full host.
    """
    name?: str
    fullName?: str

schema HTTPIngressPath:
    path?: str
    pathType: "PathType" | "Prefix" | "ImplementationSpecific" = "ImplementationSpecific"
    backend: networkingv1.IngressBackend

