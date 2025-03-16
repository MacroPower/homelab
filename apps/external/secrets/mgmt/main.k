import charts.external_secrets
import external_secrets_base

_base_values = external_secrets_base.app.charts.external_secrets.values

app = external_secrets_base.app | {
    charts.external_secrets.values = _base_values | external_secrets.Values {
        replicaCount = 2
    }
}
