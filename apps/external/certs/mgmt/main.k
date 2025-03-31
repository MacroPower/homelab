import charts.cert_manager
import external_certs_base

_baseValues = external_certs_base.app.charts.cert_manager.values

app = external_certs_base.app | {
    charts.cert_manager.values = _baseValues | cert_manager.Values {
        replicaCount = 2
    }
}
