local k = import '../../../lib/k.libsonnet';

k.core.v1.configMap.new('coredns', data={
  'Corefile': |||
    .:53 {
        errors
        health
        ready
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
        forward . 10.0.0.1
        cache 30
        loop
        reload
        loadbalance
    }
    import /etc/coredns/custom/*.server
  |||,
})

// forward . /etc/resolv.conf
