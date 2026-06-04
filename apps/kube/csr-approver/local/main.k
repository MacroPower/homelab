import kube_csr_approver_base
import charts.kubelet_csr_approver as kca

# The Talos-in-Docker node is named "local" (clusters/local/talconfig.yaml
# hostname; homelab-local-controlplane-1 is only the Docker container name)
# with an IP on the docker provisioner subnet (10.5.0.0/24), so the approver
# must recognise that name/range instead of the bare-metal kmgmt/10.10 values.
_kcaValues = kca.Values {
    providerRegex = "^local$"
    providerIpPrefixes = [
        "10.5.0.0/24",
    ]
}

app = kube_csr_approver_base.app | {
    charts.kubelet_csr_approver.values: _kcaValues
}
