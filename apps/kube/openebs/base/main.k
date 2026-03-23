import file

import konfig.models.frontend
import konfig.files

import kube_shared
import charts.openebs

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "openebs"
    tenantName = kube_shared.tenant.name

    charts.openebs = openebs.Chart {
        values: _values | openebs.Values {}
    }
}
