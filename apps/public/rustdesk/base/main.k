import file

import konfig.models.frontend
import konfig.models.frontend.networkpolicy
import konfig.models.templates.networkpolicy as npt
import konfig.files

import public_shared
import charts.rustdesk

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "rustdesk"
    tenantName = public_shared.tenant.name

    networkPolicies: {
        denyDefault = npt.denyDefault
        kubeDNSEgress = npt.kubeDNSEgress
        icmpV6Egress = npt.icmpV6Egress
        rustdeskIngress = networkpolicy.NetworkPolicy {
            name = "rustdesk-ingress"
            ingress = [{
                fromEntities = ["all"]
                toPorts = [{
                    ports = [
                        {
                            port = "21115"
                            protocol = "TCP"
                        }
                        {
                            port = "21116"
                            protocol = "ANY"
                        }
                        {
                            port = "21117"
                            protocol = "TCP"
                        }
                        {
                            port = "21118"
                            protocol = "TCP"
                        }
                        {
                            port = "21119"
                            protocol = "TCP"
                        }
                    ]
                }]
            }]
        }
    }

    charts.rustdesk = rustdesk.Chart {
        values = _values | rustdesk.Values {
            global.nameOverride = name
            global.fullnameOverride = name
        }
    }
}
