import bootstrap
import cilium_system
import kube_csr_approver

_cluster_name = "main"

app = bootstrap.app | {
    extraResources: {
        kube_csr_approver_ns = bootstrap.kube_csr_approver_ns
        cilium_system_ns = bootstrap.cilium_system_ns
    }

    charts.kubelet_csr_approver = kube_csr_approver.app.charts.kubelet_csr_approver | {
        namespace = bootstrap.kube_csr_approver_ns.metadata.name
        skipHooks = True
    }

    charts.cilium = cilium_system.app.charts.cilium | {
        namespace = bootstrap.cilium_system_ns.metadata.name
    }
}
