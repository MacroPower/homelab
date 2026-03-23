import file

import konfig.models.frontend
import konfig.models.templates.networkpolicy
import konfig.files

import kube_shared
import charts.descheduler

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "descheduler"
    tenantName = kube_shared.tenant.name

    networkPolicies = {
        denyDefault = networkpolicy.denyDefault
        kubeDNSEgress = networkpolicy.kubeDNSEgress
        kubeAPIServerEgress = networkpolicy.kubeAPIServerEgress
    }

    charts.descheduler = descheduler.Chart {
        values = _values | descheduler.Values {}
    }
}
