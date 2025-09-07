import external_secrets_base
import charts.external_secrets

_baseValues = external_secrets_base.app.charts.external_secrets.values

app = external_secrets_base.app | {
    charts.external_secrets.values = _baseValues | external_secrets.Values {
        replicaCount = 2
    }
}
