# Traefik

## MTLS (Cloud <-> Cloudflare)

Create Cloudflare Origin CA and add it as a secret.

```bash
kubectl create secret tls cloudflare-tls \
  -n kube-system \
  --key origin-ca.pk \
  --cert origin-ca.crt
```

Enable Cloudflare Authenticated Origin Pull.

Add Cloudflare CA secret for MTLS. Cert is [here][cloudflare-certificate].

```bash
kubectl create secret generic cloudflare-mtls \
  -n kube-system \
  --from-file=tls.ca=authenticated_origin_pull_ca.pem
```

Then require this in a TLSOption.

## MTLS (Cloudflare <-> Client)

When you get a client cert from cloudflare, you can convert it to a p12 file to
use it with Firefox.

```bash
openssl pkcs12 -export -out keyStore.p12 -inkey client.pk -in client.crt
```

[cloudflare-certificate]: https://developers.cloudflare.com/ssl/origin-configuration/authenticated-origin-pull/set-up/#zone-level--cloudflare-certificate
