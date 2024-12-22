import yaml
import helm
import konfig.models.frontend
import konfig.models.frontend.container
import konfig.models.frontend.secret
import konfig.models.frontend.configmap
import konfig.models.frontend.rbac
import konfig.models.frontend.storage
import konfig.models.templates.networkpolicy
import konfig.models.utils
import grafana_operator.v1beta1 as grafanav1beta1
import tenant

tenantConfiguration = tenant.tenantConfiguration

appConfiguration: frontend.App {
    name = "grafana"

    tenantName = tenantConfiguration.name
    domainName = "macro.network"
    secretStore = tenantConfiguration.secretStores.default.name

    networkPolicies = {
        denyDefault = networkpolicy.denyDefault
        kubeDNSEgress = networkpolicy.kubeDNSEgress
        kubeAPIServerEgress = networkpolicy.kubeAPIServerEgress | {
            endpointSelector.matchExpressions = [{
                key = "app.kubernetes.io/name"
                operator = "In"
                values = ["grafana-operator"]
            }]
        }
        traefikIngress = networkpolicy.traefikIngress | {
            endpointSelector.matchExpressions = [{
                key = "app.kubernetes.io/name"
                operator = "In"
                values = ["grafana"]
            }]
        }
    }

    charts.grafanaOperator = helm.template(helm.Chart {
        chart = "grafana-operator"
        targetRevision = "v5.10.0"
        repoURL = "ghcr.io/grafana/helm-charts"
        values = Values {
            resources.requests = {
                cpu = 10m
                memory = 50Mi
            }
            resources.limits = {
                cpu = 1000m
                memory = 100Mi
            }
        }
    })

    externalSecrets.grafana = grafanaCredentials

    extraResources.grafana = grafanav1beta1.Grafana {
        metadata = utils.AppMetadataBuilder({
            name = "grafana"
            labels = {
                "app.kubernetes.io/name" = "grafana"
                "dashboards" = "grafana"
            }
        }, utils.ArgoCDOptions {
            sync.SkipDryRunOnMissingResource = True
        })
        spec.config = GrafanaConfigBuilder(domainName)
        spec.deployment.metadata = {}
        spec.deployment.spec = {
            replicas = 2
            template.spec.containers = [
                {
                    name = "grafana"
                    image = "grafana/grafana:11.1.0"
                    env = utils.EnvBuilder(grafanaEnv)
                    resources.requests = {
                        cpu = "250m"
                        memory = "1Gi"
                    }
                    resources.limits = {
                        memory = "2Gi"
                    }
                    volumeMounts = [
                        {
                            name = "provisioning-config"
                            mountPath = "/etc/grafana/provisioning/dashboards"
                        }
                        {
                            name = "dashboards"
                            mountPath = "/var/lib/grafana/dashboards"
                        }
                    ]
                }
                {
                    name = "k8s-sidecar"
                    image = "ghcr.io/kiwigrid/k8s-sidecar:1.27.4"
                    env = utils.EnvBuilder(grafanaSidecarEnv)
                    resources.requests = {
                        cpu = "5m"
                        memory = "100Mi"
                    }
                    resources.limits = {
                        cpu = "100m"
                        memory = "200Mi"
                    }
                    volumeMounts = [
                        {
                            name = "dashboards"
                            mountPath = "/var/lib/grafana/dashboards"
                        }
                    ]
                }
            ]
            template.spec.volumes = [
                {
                    name = "provisioning-config"
                    configMap.name = "provisioning-config"
                }
                {
                    name = "dashboards"
                    emptyDir = {}
                }
            ]
        }
    }

    configMaps.provisioningConfig = configmap.ConfigMap {
        name = "provisioning-config"
        data = {
            "provisioning.yaml" = yaml.encode({
                apiVersion = 1
                providers = [{
                    name = "configmap-dashboard-provider"
                    orgId = 1
                    folder = ""
                    folderUid = ""
                    type = "file"
                    disableDeletion = False
                    updateIntervalSeconds = 10
                    allowUiUpdates = False
                    options.path = "/var/lib/grafana/dashboards"
                    options.foldersFromFilesStructure = True
                }]
            })
        }
    }

    externalSecrets.grafanaDatabaseCredentials = databaseCredentials
    postgresDatabases.grafana = storage.PostgresDatabase {
        name = "grafana"
        deletionPolicy = "Delete"
        ownerPasswordSecretRef = databaseCredentials.getSecretKeyRef("GRAFANA_DB_PASS")
        providerConfigName = "postgres-shared"
    }

    namespaceSecretStores.authentik = authentikNamespaceSecrets
    externalSecrets.oauth = oAuthSecrets

    clusterRoles.sidecarRole = rbac.ClusterRole {
        name = "sidecar-role"
        rules = [{
            apiGroups = [""]
            resources = ["configmaps"]
            verbs = ["get", "list", "watch"]
        }]
    }
    clusterRoleBindings.sidecarRoleBinding = rbac.ClusterRoleBinding {
        name = "sidecar-role-binding"
        roleRef = clusterRoles.sidecarRole.getRef()
        subjects = [{
            kind = "ServiceAccount"
            name = "grafana-sa"
        }]
    }
}

GrafanaConfigBuilder = lambda domainName: str {
    _grafanaDomain = "grafana.{}".format(domainName)
    _authentikDomain = "authentik.{}".format(domainName)
    {
        "analytics" = {
            reporting_enabled = "false"
        }
        "server" = {
            protocol = "http"
            domain = _grafanaDomain
            root_url = "https://{}".format(_grafanaDomain)
        }
        "database" = {
            type = "postgres"
            host = "postgres-shared-rw.postgres-shared.svc:5432"
            name = "grafana"
            user = "grafana"
            ssl_mode = "require"
        }
        "log" = {
            mode = "console"
        }
        "log.console" = {
            level = "info"
            format = "json"
        }
        "auth" = {
            oauth_auto_login = "true"
            signout_redirect_url = "https://{}/application/o/grafana/end-session".format(_authentikDomain)
        }
        "auth.generic_oauth" = {
            enabled = "true"
            name = "authentik"
            scopes = "openid email profile"
            auth_url = "https://{}/application/o/authorize/".format(_authentikDomain)
            token_url = "https://{}/application/o/token/".format(_authentikDomain)
            api_url = "https://{}/application/o/userinfo/".format(_authentikDomain)
            role_attribute_path = "contains(groups[*], 'Grafana Admins') && 'Admin' || contains(groups[*], 'Grafana Editors') && 'Editor' || 'Viewer'"
        }
    }
}

grafanaCredentials = secret.ExternalSecret {
    name = "grafana-credentials"
    data = {
        GRAFANA_ADMIN_USER = {}
        GRAFANA_ADMIN_PASS = {}
    }
}

authentikNamespaceSecrets = secret.NamespaceSecretStore {
    remoteNamespace = "authentik"
}

oAuthSecrets = secret.ExternalSecret {
    name = "grafana-oauth"
    secretStoreRef = authentikNamespaceSecrets.getRef()
    data = {
        CLIENT_ID = {
            remoteRef.key = "authentik-grafana"
            remoteRef.property = "client_id"
        }
        CLIENT_SECRET = {
            remoteRef.key = "authentik-grafana"
            remoteRef.property = "client_secret"
        }
    }
}

databaseCredentials = secret.ExternalSecret {
    name = "grafana-database-credentials"
    data = {
        GRAFANA_DB_PASS = {}
    }
}

grafanaEnv: container.EnvMap = {
    GF_SECURITY_ADMIN_USER = grafanaCredentials.getSecretKeyEnvRef("GRAFANA_ADMIN_USER")
    GF_SECURITY_ADMIN_PASSWORD = grafanaCredentials.getSecretKeyEnvRef("GRAFANA_ADMIN_PASS")
    GF_AUTH_GENERIC_OAUTH_CLIENT_ID = oAuthSecrets.getSecretKeyEnvRef("CLIENT_ID")
    GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET = oAuthSecrets.getSecretKeyEnvRef("CLIENT_SECRET")
    GF_DATABASE_PASSWORD = databaseCredentials.getSecretKeyEnvRef("GRAFANA_DB_PASS")
}

grafanaSidecarEnv: container.EnvMap = {
    LABEL = "grafana_dashboard"
    LABEL_VALUE = "1"
    FOLDER_ANNOTATION = "grafana_folder"
    FOLDER = "/var/lib/grafana/dashboards"
    NAMESPACE = "ALL"
    RESOURCE = "configmap"
}
