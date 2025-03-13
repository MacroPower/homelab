import file

import k8s.api.core.v1 as corev1

import konfig.models.frontend
import konfig.models.frontend.secret

kube_csr_approver_ns = corev1.Namespace {
    metadata.name = "kube-csr-approver"
}
cilium_system_ns = corev1.Namespace {
    metadata.name = "cilium-system"
}

app: frontend.App {
    name = "bootstrap"
    tenantName = "default"

    secrets.doppler_credentials = secret.Secret {
        name = "doppler-credentials"
        namespace = "kube-system"
        stringData = {
            token = file.read_env("DOPPLER_TOKEN")
        }
    }
}
