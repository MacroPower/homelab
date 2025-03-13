import charts.kubelet_csr_approver as kca
import kube_csr_approver_base

_kcaValues = kca.Values {
    providerRegex = "^kmgmt\d\d$"
    providerIpPrefixes = [
        "10.10.0.0/16",
        "fc42:0:0:a::/64",
    ]
}

app = kube_csr_approver_base.app | {
    charts.kubelet_csr_approver.values: _kcaValues
}
