import file

import konfig.models.frontend
import konfig.files

import ci_shared
import charts.gha_runner_scale_set_controller as arc_controller

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "actions-runner-controller"
    tenantName = ci_shared.tenant.name

    charts.gha_runner_scale_set_controller = arc_controller.Chart {
        values = _values | arc_controller.Values {}
    }
}
