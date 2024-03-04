local k = import '../../../lib/k.libsonnet';

k.core.v1.configMap.new('coredns', data={
  Corefile: |||
    .:53 {
        errors
        health
        ready
        rewrite continue {
          name exact authentik.home.macro.network authentik-server.authentik.svc.cluster.local
        }
        kubernetes cluster.local in-addr.arpa ip6.arpa {
          pods insecure
          fallthrough in-addr.arpa ip6.arpa
        }
        hosts /etc/coredns/NodeHosts {
          ttl 60
          reload 15s
          fallthrough
        }
        prometheus :9153
        forward . 10.10.0.1:53 [2603:6010:5300:ad0a::1]:53
        cache 30
        loop
        reload
        loadbalance
    }
    import /etc/coredns/custom/*.server
  |||,
})

// forward . /etc/resolv.conf
