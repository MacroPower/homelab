import konfig.models.templates.networkpolicy as npt

import ci_actions_runner_controller_base

# The gha-runner-scale-set-controller is a single Deployment with no
# Docker-unsafe items (base already pins replicaCount=1, no HW nodeSelectors,
# no storage, no LoadBalancer, no external secrets). Inherit base verbatim and
# carry the same network policies as the main overlay; they use the
# kube-apiserver/kube-dns entities and resolve fine on the local cluster.
app = ci_actions_runner_controller_base.app | {
    networkPolicies: {
        denyDefault = npt.denyDefault
        kubeDNSEgress = npt.kubeDNSEgress
        icmpV6Egress = npt.icmpV6Egress
        kubeAPIServerEgress = npt.kubeAPIServerEgress
    }
}
