import file

import konfig.files
import konfig.objects

import public_rustdesk_base
import cluster
import charts.rustdesk

_baseValues = public_rustdesk_base.app.charts.rustdesk.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Docker-safe local overlay for rustdesk. Differences from main/main.k:
#  - domainName resolves to cluster.DOMAIN_NAME (local.test) instead of the
#    hardcoded jacobcolvin.com, so routes.rustdeskWeb is reachable locally.
#  - The rustdesk-keypair ExternalSecret keys (RUSTDESK_KEY_PRIV / RUSTDESK_KEY_PUB)
#    are redirected to "dummy" so the offline fake ClusterSecretStore answers them.
#    The mounted keypair is therefore not the real prod key; hbbs regenerates a key
#    on first start, which is fine for a throwaway local cluster.
#  - The ws-id / ws-relay HTTPRoute hostnames are repointed from rustdesk.jacobcolvin.com
#    to rustdesk.${domainName} so they attach to the local gateway hostname.
app = public_rustdesk_base.app | {
    domainName = cluster.DOMAIN_NAME
    charts.rustdesk.values = _values

    routes.rustdeskWeb.gatewayRef = {
        name = "public-gateway"
        namespace = "envoy-gateway"
    }

    externalSecrets.keypair.data: {
        RUSTDESK_KEY_PRIV.remoteRef.key = "dummy"
        RUSTDESK_KEY_PUB.remoteRef.key = "dummy"
    }

    extraResources.wsIdRoute.spec.hostnames = ["rustdesk.${cluster.DOMAIN_NAME}"]
    extraResources.wsRelayRoute.spec.hostnames = ["rustdesk.${cluster.DOMAIN_NAME}"]
}
