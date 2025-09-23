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

_values = files.read_yaml(file.current(), "values.yaml")

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

app = frontend.App {
    name = "opencloud"
    tenantName = public.tenant.name

    secretStore = public.shared.secretStores.default.name
    externalSecrets: {
        opencloudCredentials = _opencloudCredentials
        opencloudOIDCClient = _opencloudOIDCClient
    }

    charts.opencloud = opencloud.Chart {
        values: _values | opencloud.Values {
            opencloud: {
                existingSecret = _opencloudCredentials.name
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
            icon = "open-cloud"
        }
    }
}
