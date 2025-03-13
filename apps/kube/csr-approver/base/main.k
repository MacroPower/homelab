import charts.kubelet_csr_approver
import konfig.models.frontend
import konfig.models.templates.networkpolicy
import kube_tenant

app: frontend.App {
    name = "csr-approver"
    tenantName = kube_tenant.tenantConfiguration.name

    networkPolicies = {
        denyDefault = networkpolicy.denyDefault
        kubeDNSEgress = networkpolicy.kubeDNSEgress
        kubeAPIServerEgress = networkpolicy.kubeAPIServerEgress
    }

    charts.kubelet_csr_approver = kubelet_csr_approver.Chart {
        values: kubelet_csr_approver.Values {
            bypassDnsResolution = True
            ignoreNonSystemNode = True
            metrics.serviceMonitor.enabled = False
            resources: {
                requests: {
                    cpu = "10m"
                    memory = "10Mi"
                }
                limits: {
                    cpu = "100m"
                    memory = "100Mi"
                }
            }
        }
    }
}
