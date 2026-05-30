import file

import konfig.files
import konfig.objects

import external_secrets_base
import charts.external_secrets

_baseValues = external_secrets_base.app.charts.external_secrets.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# values.yaml collapses the operator/webhook/cert-controller to one replica each
# and turns off leader election; the ServiceMonitor stays enabled because the
# Prometheus operator CRDs are installed in the local environment.
#
# The `external` ClusterSecretStore is the tenant's shared-tier store
# (apps/external/_tenant/shared), which the `{tenant}-shared` ApplicationSet
# renders here with a fake provider because this cluster sets
# `fake_secret_stores=true` -- so no stand-in store is hand-written in this app.
app = external_secrets_base.app | {
    charts.external_secrets.values = _values | external_secrets.Values {}
}
