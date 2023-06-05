local ingressHost = std.extVar('ingressHost');

[{
  apiVersion: 'cert-manager.io/v1',
  kind: 'Certificate',
  metadata: {
    name: 'transmission-webdav-cert',
  },
  spec: {
    secretName: 'transmission-webdav-cert',
    duration: '8760h0m0s',
    issuerRef: {
      name: 'letsencrypt-prod',
    },
    dnsNames: [ingressHost],
  },
}]
