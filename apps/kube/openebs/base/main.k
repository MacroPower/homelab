import file

import kube
import charts.openebs
import konfig.models.frontend
import konfig.utils

_values = utils.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "openebs"
    tenantName = kube.tenant.name

    charts.openebs = openebs.Chart {
        values: _values | openebs.Values {}
    }
}
