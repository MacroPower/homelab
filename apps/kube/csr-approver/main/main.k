import kube_csr_approver_base
import charts.kubelet_csr_approver as kca

_kcaValues = kca.Values {
    providerRegex = "^k(main|nas|robot)\d\d$"
    providerIpPrefixes = [
        "10.10.0.0/16"
        "10.42.2.20/32"
        "fc42:0:0:a::/64"
    ]
}

app = kube_csr_approver_base.app | {
    charts.kubelet_csr_approver.values: _kcaValues
}
