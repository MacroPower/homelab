import file

import konfig.models.frontend
import konfig.models.templates.networkpolicy as npt
import konfig.files

import kube
import charts.volsync

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "volsync"
    tenantName = kube.tenant.name

    networkPolicies: {
        denyDefault = npt.denyDefault
        kubeDNSEgress = npt.kubeDNSEgress
        icmpV6Egress = npt.icmpV6Egress
        kubeAPIServerEgress = npt.kubeAPIServerEgress
        openMetricsIngress = npt.openMetricsIngress
    }

    charts.volsync = volsync.Chart {
        values: _values | volsync.Values {}
    }
}
