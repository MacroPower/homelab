import file

import charts.descheduler
import konfig.models.frontend
import konfig.models.templates.networkpolicy
import konfig.utils
import kube

_values = utils.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "descheduler"
    tenantName = kube.tenant.name

    networkPolicies = {
        denyDefault = networkpolicy.denyDefault
        kubeDNSEgress = networkpolicy.kubeDNSEgress
        kubeAPIServerEgress = networkpolicy.kubeAPIServerEgress
    }

    charts.descheduler = descheduler.Chart {
        values = _values | descheduler.Values {}
    }
}
