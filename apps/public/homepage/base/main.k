import file
import yaml

import konfig.models.frontend
import konfig.models.frontend.configmap
import konfig.models.frontend.gateway
import konfig.models.frontend.networkpolicy
import konfig.models.frontend.rbac
import konfig.models.templates.networkpolicy as npt
import konfig.files

import public
import charts.homepage

_values = files.read_yaml(file.current(), "values.yaml")

bookmarks = files.read_yaml(file.current(), "config/bookmarks.yaml")
kubernetes = files.read_yaml(file.current(), "config/kubernetes.yaml")
services = files.read_yaml(file.current(), "config/services.yaml")
settings = files.read_yaml(file.current(), "config/settings.yaml")
widgets = files.read_yaml(file.current(), "config/widgets.yaml")

_homepagePort = 3000

app = frontend.App {
    name = "homepage"
    tenantName = public.tenant.name

    networkPolicies: {
        denyDefault = npt.denyDefault
        kubeDNSEgress = npt.kubeDNSEgress
        icmpV6Egress = npt.icmpV6Egress
        kubeAPIServerEgress = npt.kubeAPIServerEgress
        gatewayIngress = npt.envoyGatewayIngress
        githubEgress = networkpolicy.NetworkPolicy {
            name = "github-egress"
            egress = [
                {
                    toFQDNs = [{
                        matchPattern = "api.github.com"
                    }]
                    toPorts = [{
                        ports = [{
                            protocol = "TCP"
                            port = "443"
                        }]
                    }]
                }
            ]
        }
    }

    charts.homepage = homepage.Chart {
        values: _values | homepage.Values {
            global.nameOverride = name
            global.fullnameOverride = name
            service.app.ports.http.port = _homepagePort
        }
    }

    configMaps.homepageConfig = configmap.ConfigMap {
        name = "homepage-config"
        data: {
            "bookmarks.yaml" = yaml.encode(bookmarks)
            "kubernetes.yaml" = yaml.encode(kubernetes)
            "services.yaml" = yaml.encode(services)
            "settings.yaml" = yaml.encode(settings)
            "widgets.yaml" = yaml.encode(widgets)
        }
    }

    routes.homepage = gateway.Route {
        gatewayRef = public.tenant.gateways.default
        services.homepage = {
            name = name
            port = _homepagePort
        }
        homepage = {
            name = "Homepage"
            description = "This Homepage"
            group = "Apps"
            icon = "homepage"
        }
    }

    clusterRoles.homepage = rbac.ClusterRole {
        name = name
        rules = [
            {
                apiGroups = [""]
                resources = ["namespaces", "pods", "nodes"]
                verbs = ["get", "list"]
            }
            {
                apiGroups = ["extensions", "networking.k8s.io"]
                resources = ["ingresses"]
                verbs = ["get", "list"]
            }
            {
                apiGroups = ["gateway.networking.k8s.io"]
                resources = ["httproutes", "gateways"]
                verbs = ["get", "list"]
            }
            {
                apiGroups = ["metrics.k8s.io"]
                resources = ["nodes", "pods"]
                verbs = ["get", "list"]
            }
        ]
    }

    clusterRoleBindings.homepage = rbac.ClusterRoleBinding {
        name = name
        roleRef = clusterRoles.homepage.getRef()
        subjects = [
            {
                kind = "ServiceAccount"
                name = name
            }
        ]
    }
}
