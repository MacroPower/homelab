import kube_csr_approver_base
import charts.kubelet_csr_approver as kca

_kcaValues = kca.Values {
    providerRegex = "^krobot\d\d$"
    providerIpPrefixes = [
        "10.42.0.0/16",
    ]
}

app = kube_csr_approver_base.app | {
    charts.kubelet_csr_approver.values: _kcaValues
}
