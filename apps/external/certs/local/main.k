import file

import konfig.files
import konfig.objects

import external_certs_base
import charts.cert_manager
import charts.cert_manager.api.v1 as certmanagerv1

_baseValues = external_certs_base.app.charts.cert_manager.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Docker-safe cert-manager. ACME issuance can't work offline (the base's Let's
# Encrypt / Cloudflare DNS-01 ClusterIssuers and the public-ingress Certificate
# need real DNS and a reachable ACME endpoint), so drop them and stand up a
# SelfSigned ClusterIssuer instead. A KCL union cannot delete by omission, hence
# the explicit Undefined. The base's Cloudflare ExternalSecrets are left in place
# (dropping them via Undefined would feed the ExternalSecretMixin a null entry);
# orphaned with their issuers gone, they render as harmless dummies against the
# fake offline store (fake_secret_stores=true).
app = external_certs_base.app | {
    charts.cert_manager.values = _values | cert_manager.Values {}

    extraResources.cfMacroNetworkCI = Undefined
    extraResources.cfJacobColvinComCI = Undefined
    extraResources.cloudflarePublicIngress = Undefined

    extraResources.selfSignedCI = certmanagerv1.ClusterIssuer {
        metadata.name = "selfsigned-issuer"
        spec.selfSigned = {}
    }
}
