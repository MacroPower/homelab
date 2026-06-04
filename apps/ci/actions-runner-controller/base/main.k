import file

import konfig.models.frontend
import konfig.files
import konfig.models.templates.networkpolicy as npt

import ci_shared
import charts.gha_runner_scale_set_controller as arc_controller

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "actions-runner-controller"
    tenantName = ci_shared.tenant.name

    networkPolicies: {
        denyDefault = npt.denyDefault
        kubeDNSEgress = npt.kubeDNSEgress
        icmpV6Egress = npt.icmpV6Egress
        kubeAPIServerEgress = npt.kubeAPIServerEgress
    }

    charts.gha_runner_scale_set_controller = arc_controller.Chart {
        values = _values | arc_controller.Values {}
    }
}
