import models.frontend.networkpolicy

denyDefault = networkpolicy.NetworkPolicy {
    name = "deny-default"
    ingress = [{}]
    egress = [{}]
}

icmpV6Egress = networkpolicy.NetworkPolicy {
    name = "icmp-v6-egress"
    egress = [
        {
            toEntities = ["all"]
            icmps = [
                {
                    fields = [
                        {
                            family = "IPv6"
                            type = "NeighborSolicitation"
                        }
                        {
                            family = "IPv6"
                            type = "NeighborAdvertisement"
                        }
                        {
                            family = "IPv6"
                            type = "RouterSolicitation"
                        }
                        {
                            family = "IPv6"
                            type = "RouterAdvertisement"
                        }
                        {
                            family = "IPv6"
                            type = "PacketTooBig"
                        }
                        {
                            family = "IPv6"
                            type = "EchoRequest"
                        }
                        {
                            family = "IPv6"
                            type = "EchoReply"
                        }
                        {
                            family = "IPv6"
                            type = "DestinationUnreachable"
                        }
                        {
                            family = "IPv6"
                            type = "TimeExceeded"
                        }
                        {
                            family = "IPv6"
                            type = "ParameterProblem"
                        }
                    ]
                }
            ]
        }
    ]
}

kubeDNSEgress = networkpolicy.NetworkPolicy {
    name = "kube-dns-egress"
    egress = [
        {
            toEndpoints = [
                {
                    matchLabels = {
                        "io.kubernetes.pod.namespace": "kube-system"
                        "k8s-app": "kube-dns"
                    }
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

envoyGatewayIngress = networkpolicy.NetworkPolicy {
    name = "envoy-gateway-ingress"
    ingress = [
        {
            fromEndpoints = [
                {
                    matchExpressions = [
                        {
                            key = "k8s:io.kubernetes.pod.namespace"
                            operator = "In"
                            values = ["envoy-gateway"]
                        }
                    ]
                }
            ]
        }
    ]
}
