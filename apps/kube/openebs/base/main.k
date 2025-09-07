import file

import konfig.models.frontend
import konfig.files

import kube
import charts.openebs

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "openebs"
    tenantName = kube.tenant.name

    charts.openebs = openebs.Chart {
        values: _values | openebs.Values {}
    }
}
