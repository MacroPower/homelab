import file

import konfig.models.frontend
import konfig.models.frontend.gateway
import konfig.models.frontend.networkpolicy
import konfig.models.templates.networkpolicy as npt
import konfig.files

import truenas
import charts.truecommand

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "command"
    tenantName = truenas.tenant.name
    charts.truecommand = truecommand.Chart {
        values: _values | truecommand.Values {}
    }
    routes.truecommand = gateway.Route {
        hostnames = ["truecommand.jacobcolvin.com"]
        gatewayRef = truenas.tenant.gateways.public
        services.server = {
            name = "truecommand"
            port = 80
        }
        homepage = {
            name = "TrueCommand"
            description = "Centralized TrueNAS Management"
            group = "Apps"
            icon = "truecommand"
        }
    }
    networkPolicies: {
        denyDefault = npt.denyDefault
        kubeDNSEgress = npt.kubeDNSEgress
        icmpV6Egress = npt.icmpV6Egress
        gatewayIngress = npt.envoyGatewayIngress
        ixsystemsEgress = networkpolicy.NetworkPolicy {
            name = "ixsystems-egress"
            egress = [{
                toFQDNs = [
                    {matchName = "update-tc.ixsystems.com"}
                ]
                toPorts = [{
                    ports = [{
                        port = "443"
                        protocol = "TCP"
                    }]
                }]
            }]
        }
        truenasEgress = networkpolicy.NetworkPolicy {
            name = "truenas-egress"
            egress = [{
                toFQDNs = [
                    {matchName = "nas01.cin.macro.network"}
                    {matchName = "robot01.fsn.macro.network"}
                ]
                toPorts = [{
                    ports = [{
                        port = "443"
                        protocol = "ANY"
                    }]
                }]
            }]
        }
    }
}
