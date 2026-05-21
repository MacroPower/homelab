import konfig.models.templates.networkpolicy as npt

import ci_actions_runner_controller_base

app = ci_actions_runner_controller_base.app | {
    networkPolicies: {
        denyDefault = npt.denyDefault
        kubeDNSEgress = npt.kubeDNSEgress
        icmpV6Egress = npt.icmpV6Egress
        kubeAPIServerEgress = npt.kubeAPIServerEgress
    }
}
