import file

import cilium_system_base
import konfig.utils

_valueFile = utils.abs_path(file.current(), "values.yaml")

app = cilium_system_base.app | {
    charts.cilium.valueFiles += [_valueFile]
}
