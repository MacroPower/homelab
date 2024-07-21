import models.frontend.networkpolicy

denyDefault = networkpolicy.NetworkPolicy {
    name = "deny-default"
    ingress = [{}]
    egress = [{}]
}

kubeDNSEgress = networkpolicy.NetworkPolicy {
    name = "kube-dns-egress"
    egress = [
        {
            toEndpoints = [
                {
                    matchExpressions = [
                        {
                            key = "k8s:io.kubernetes.pod.namespace"
                            operator = "In"
                            values = ["kube-system"]
                        }
                        {
                            key = "k8s:k8s-app"
                            operator = "In"
                            values = ["kube-dns"]
                        }
                    ]
                }
            ]
            toPorts = [
                {
                    ports = [
                        {
                            port = "53"
                            protocol = "ANY"
                        }
                    ]
                    rules.dns = [
                        {
                            matchPattern = "*"
                        }
                    ]
                }
            ]
        }
    ]
}

kubeAPIServerEgress = networkpolicy.NetworkPolicy {
    name = "kube-apiserver-egress"
    egress = [
        {
            toEntities = [
                "kube-apiserver"
            ]
        }
    ]
}

traefikIngress = networkpolicy.NetworkPolicy {
    name = "traefik-ingress"
    ingress = [
        {
            fromEndpoints = [
                {
                    matchExpressions = [
                        {
                            key = "k8s:io.kubernetes.pod.namespace"
                            operator = "In"
                            values = ["traefik"]
                        }
                    ]
                }
            ]
        }
    ]
}
