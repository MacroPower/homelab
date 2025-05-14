import charts.external_secrets
import external_secrets_base

_baseValues = external_secrets_base.app.charts.external_secrets.values

app = external_secrets_base.app | {
    charts.external_secrets.values = _baseValues | external_secrets.Values {}
}
