import file

import cilium_system_base

app = cilium_system_base.app | {
    charts.cilium.valueFiles += [
        file.abs(file.current()+"/../values.yaml"),
    ]
}
