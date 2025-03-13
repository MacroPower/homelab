import file

import cilium_system_base
import filepath

_current_dir = filepath.dir(file.current())

app = cilium_system_base.app | {
    charts.cilium.valueFiles += [
        filepath.join([_current_dir, "values.yaml"]),
    ]
}
