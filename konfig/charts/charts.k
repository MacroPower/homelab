import helm

charts: helm.Charts = {
    kubelet_csr_approver: {
        chart = "kubelet-csr-approver"
        repoURL = "https://postfinance.github.io/kubelet-csr-approver"
        targetRevision = "1.2.6"
        schemaGenerator = "AUTO"
    }
    cilium: {
        chart = "cilium"
        repoURL = "https://helm.cilium.io"
        targetRevision = "1.17.1"
        schemaGenerator = "AUTO"
    }
    external_secrets: {
        chart = "external-secrets"
        repoURL = "https://charts.external-secrets.io/"
        targetRevision = "0.14.3"
        schemaGenerator = "AUTO"
        crdGenerator = "TEMPLATE"
        values: {
            crds: {
                conversion: {
                    enabled = False
                }
            }
        }
    }
    argo_cd: {
        chart = "argo-cd"
        repoURL = "https://argoproj.github.io/argo-helm"
        targetRevision = "7.8.11"
        schemaGenerator = "AUTO"
        crdGenerator = "TEMPLATE"
    }
    grafana_operator: {
        chart = "grafana-operator"
        repoURL = "oci://ghcr.io/grafana/helm-charts/grafana-operator"
        targetRevision = "v5.16.0"
        schemaGenerator = "AUTO"
        values: {
            rbac: {
                create = False
            }
        }
    }
    descheduler: {
        chart = "descheduler"
        repoURL = "https://kubernetes-sigs.github.io/descheduler/"
        targetRevision = "0.30.1"
        schemaGenerator = "AUTO"
    }
}
