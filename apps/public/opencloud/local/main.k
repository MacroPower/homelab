import file

import konfig.files
import konfig.objects

import public_opencloud_base
import cluster
import charts.opencloud

_baseValues = public_opencloud_base.app.charts.opencloud.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Single-node tald cluster: NATS cannot form a 3-node cluster and JetStream
# streams cannot reach a quorum of 3. Disable clustering, drop the PDB, run a
# single replica, shrink JetStream stores, and reduce every stream's replica
# count to 1. ExternalSecret remoteRefs are redirected to the fake provider's
# "dummy" key. Hostnames flow from clusters/local (*.local.test).

# Patch every NACK Stream extraResource down to a single replica. The dict also
# carries the NACK Account (natsAccount), which has no spec.replicas, so guard on
# the presence of that attribute before patching.
_extraResources = {
    k: (r | {spec.replicas = 1}) if "replicas" in r.spec else r
    for k, r in public_opencloud_base.app.extraResources
}

# Rebuild each ExternalSecret's data map with the remoteRef.key pinned to the
# fake provider's "dummy" key. The OIDC client uses the hyphenated "client-id"
# key, which requires a quoted config-literal key.
_externalSecrets = public_opencloud_base.app.externalSecrets | {
    opencloudCredentials.data.adminPassword.remoteRef.key = "dummy"
    opencloudOIDCClient.data = {
        "client-id" = {remoteRef.key = "dummy"}
    }
    collaboraCredentials.data.username.remoteRef.key = "dummy"
    collaboraCredentials.data.password.remoteRef.key = "dummy"
}

app = public_opencloud_base.app | {
    domainName = cluster.DOMAIN_NAME

    externalSecrets = _externalSecrets

    charts.opencloud.values = _values | opencloud.Values {}

    # NATS: collapse the HA cluster to a single embedded JetStream node.
    charts.nats.values.config.cluster.enabled = False
    charts.nats.values.config.cluster.replicas = 1
    charts.nats.values.podDisruptionBudget.enabled = False
    charts.nats.values.config.jetstream.memoryStore.maxSize = "256Mi"
    charts.nats.values.config.jetstream.fileStore.pvc.size = "5Gi"

    extraResources = _extraResources
}
