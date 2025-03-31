import file

import charts.cert_manager
import external
import konfig.models.frontend
import konfig.utils

_values = utils.read_yaml(file.current(), "values.yaml")

app: frontend.App {
    name = "certs"
    tenantName = external.tenant.name
    namespace = "{}-{}".format(tenantName, name)

    charts.cert_manager = cert_manager.Chart {
        values: _values | cert_manager.Values {
            global: {
                leaderElection.namespace = namespace
            }
        }
    }
}
