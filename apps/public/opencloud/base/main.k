import file
import yaml

import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.models.frontend.gateway
import konfig.models.utils
import konfig.files
import helm

import public
import charts.opencloud
import charts.nats
import charts.nack.api.v1beta2 as nackv1beta2
import charts.envoy_gateway.api.v1alpha1 as gatewayv1alpha1
import charts.envoy_gateway.api.v1 as gatewayv1

_values = files.read_yaml(file.current(), "values.yaml")
_valuesNats = files.read_yaml(file.current(), "values-nats.yaml")

_opencloudCredentials = secret.ExternalSecret {
    name = "opencloud-credentials"
    data: {
        "adminPassword" = {
            remoteRef.key = "OPENCLOUD_ADMIN_PASSWORD"
        }
    }
}

_opencloudOIDCClient = secret.ExternalSecret {
    name = "opencloud-oidc-client"
    data: {
        "client-id" = {
            remoteRef.key = "OPENCLOUD_AUTH0_CLIENT_ID"
        }
    }
}

_collaboraCredentials = secret.ExternalSecret {
    name = "collabora-credentials"
    data: {
        "username" = {
            remoteRef.key = "OPENCLOUD_COLLABORA_USERNAME"
        }
        "password" = {
            remoteRef.key = "OPENCLOUD_COLLABORA_PASSWORD"
        }
    }
}

_collaboraWebSocketPolicy = gatewayv1alpha1.BackendTrafficPolicy {
    metadata.name = "opencloud-collabora-websocket-policy"
    spec: {
        targetRefs = [{
            group = "gateway.networking.k8s.io"
            kind = "HTTPRoute"
            name = "opencloud-collabora-websockets"
        }]
        httpUpgrade = [{
            $type = "websocket"
        }]
    }
}

_collaboraClientTrafficPolicy = gatewayv1alpha1.ClientTrafficPolicy {
    metadata.name = "opencloud-collabora-http1-policy"
    spec: {
        targetRefs = [{
            group = "gateway.networking.k8s.io"
            kind = "HTTPRoute"
            name = "opencloud-collabora-websockets"
        }]
        http1 = {}
    }
}

_collaboraWebSocketRoute = gatewayv1.HTTPRoute {
    metadata = {
        name = "opencloud-collabora-websockets"
    }
    spec = {
        hostnames = ["collabora.main.cin.macro.network"]
        parentRefs = [{
            group = "gateway.networking.k8s.io"
            kind = "Gateway"
            name = "cluster-gateway"
            namespace = "envoy-gateway"
            sectionName = "https"
        }]
        rules = [
            {
                matches = [{
                    path = {
                        $type = "RegularExpression"
                        value = "^/cool/.*/ws$"
                    }
                }]
                backendRefs = [{
                    name = "opencloud-collabora"
                    port = 9980
                }]
            }
            {
                matches = [{
                    path = {
                        $type = "PathPrefix"
                        value = "/cool/adminws"
                    }
                }]
                backendRefs = [{
                    name = "opencloud-collabora"
                    port = 9980
                }]
            }
        ]
    }
}

_envVars = {
    "WEB_OIDC_SCOPE" = "openid profile email roles colvinGroups"
    "WEB_OIDC_METADATA_URL" = "https://auth.jacobcolvin.com/.well-known/openid-configuration"
    "WEB_OIDC_CLIENT_ID" = _opencloudOIDCClient.getSecretKeyEnvRef("client-id")
    "PROXY_OIDC_ACCESS_TOKEN_VERIFY_METHOD" = "none"
    "PROXY_USER_OIDC_CLAIM" = "nickname"
    "PROXY_USER_CS3_CLAIM" = "username"
    "PROXY_ROLE_ASSIGNMENT_OIDC_CLAIM" = "colvinGroups"
    "PROXY_AUTOPROVISION_CLAIM_USERNAME" = "nickname"
    "PROXY_AUTOPROVISION_CLAIM_EMAIL" = "email"
    "PROXY_AUTOPROVISION_CLAIM_DISPLAYNAME" = "name"
    "PROXY_AUTOPROVISION_CLAIM_GROUPS" = "colvinGroups"
}

_natsCluster = "opencloud-cluster"

app = frontend.App {
    name = "opencloud"
    tenantName = public.tenant.name

    secretStore = public.shared.secretStores.default.name
    externalSecrets: {
        opencloudCredentials = _opencloudCredentials
        opencloudOIDCClient = _opencloudOIDCClient
        collaboraCredentials = _collaboraCredentials
    }

    charts.nats = nats.Chart {
        values: _valuesNats | nats.Values {
            fullnameOverride = "opencloud-nats"
        }
    }

    extraResources.natsAccount = nackv1beta2.Account {
        metadata.name = "opencloud-nats"
        spec: {
            name = "opencloud-nats"
            servers = ["opencloud-nats.public-opencloud.svc.cluster.local:4222"]
        }
    }

    charts.opencloud = opencloud.Chart {
        values: _values | opencloud.Values {
            opencloud: {
                existingSecret = _opencloudCredentials.name
                nats.external: {
                    enabled = True
                    cluster = _natsCluster
                    endpoint = "opencloud-nats.public-opencloud.svc.cluster.local:4222"
                }
            }
            collabora: {
                existingSecret = _collaboraCredentials.name
            }
        }

        postRenderer = lambda resource: helm.Resource -> helm.Resource {
            if resource.kind == "Deployment" and resource.metadata.name == "opencloud-opencloud":
                resource.spec.template.spec.containers[0].env = utils.EnvBuilder(_envVars) + [
                    env
                    for env in resource.spec.template.spec.containers[0].env
                    if env.name not in [k for k in _envVars]
                ]
            resource
        }
    }

    routes.opencloud = gateway.Route {
        gatewayRef = public.tenant.gateways.default
        services.opencloud = {
            name = "opencloud-opencloud"
            port = 9200
        }
        homepage = {
            name = "OpenCloud"
            description = "File Management & Collaboration"
            group = "Apps"
            icon = "open-cloud-dark"
        }
    }
    routes.collabora = gateway.Route {
        name = "public-collabora"
        hostnames = ["collabora"]
        gatewayRef = public.tenant.gateways.default
        services.collabora = {
            name = "opencloud-collabora"
            port = 9980
        }
    }

    extraResources: {
        collaboraWebSocketPolicy = _collaboraWebSocketPolicy
        collaboraClientTrafficPolicy = _collaboraClientTrafficPolicy
        collaboraWebSocketRoute = _collaboraWebSocketRoute
        streamMainQueue = streamMainQueue
        streamKvCacheUserinfo = streamKvCacheUserinfo
        streamKvUserlog = streamKvUserlog
        streamKvActivitylog = streamKvActivitylog
        streamKvPostprocessing = streamKvPostprocessing
        streamKvIdsStorageUsers = streamKvIdsStorageUsers
        streamKvStorageUsers = streamKvStorageUsers
        streamKvEventhistory = streamKvEventhistory
        streamKvServiceRegistry = streamKvServiceRegistry
        streamKvSettingsCache = streamKvSettingsCache
        streamKvStorageSystem = streamKvStorageSystem
        streamKvCacheRoles = streamKvCacheRoles
        streamKvProxy = streamKvProxy
        streamKvOpencloudPkg = streamKvOpencloudPkg
    }
}
