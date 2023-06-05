local ingressHost = std.extVar('ingressHost');

[{
  apiVersion: 'cert-manager.io/v1',
  kind: 'Certificate',
  metadata: {
    name: 'linkerd-tunnel-cert',
  },
  spec: {
    secretName: 'linkerd-tunnel-cert',
    duration: '2160h0m0s', // 90d
    renewBefore: '720h0m0s', // 30d
    issuerRef: {
      name: 'letsencrypt-prod',
    },
    dnsNames: [ingressHost],
  },
}]
