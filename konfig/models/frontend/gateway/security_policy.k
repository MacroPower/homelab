import charts.envoy_gateway.api.v1 as gatewayv1
import charts.envoy_gateway.api.v1alpha1 as gatewayv1alpha1
import models.frontend.common

schema SecurityPolicy(common.Metadata):
    """
    Abstraction of SecurityPolicy configuration.

    Attributes
    ----------
    oidcClientRef:
        Name of the Kubernetes Secret containing the OIDC Client credentials.
        Must have keys "client-id" and "client-secret".
    """
    oidcClientRef: str
    oidcIssuer: str
    redirectURL?: str
    logoutPath?: str
