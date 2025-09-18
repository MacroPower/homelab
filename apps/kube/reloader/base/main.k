import file

import konfig.models.frontend
import konfig.models.templates.networkpolicy as npt
import konfig.files

import kube
import charts.reloader

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "reloader"
    tenantName = kube.tenant.name

    networkPolicies: {
        denyDefault = npt.denyDefault
        kubeDNSEgress = npt.kubeDNSEgress
        icmpV6Egress = npt.icmpV6Egress
        kubeAPIServerEgress = npt.kubeAPIServerEgress
        openMetricsIngress = npt.openMetricsIngress
    }

    charts.reloader = reloader.Chart {
        values: _values | reloader.Values {}
    }
}
