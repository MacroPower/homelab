import file

import konfig.models.frontend
import konfig.models.frontend.gateway
import konfig.files

import truenas
import charts.truecommand

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "command"
    tenantName = truenas.tenant.name

    charts.truecommand = truecommand.Chart {
        values: _values | truecommand.Values {}
    }

    routes.truecommand = gateway.Route {
        hostnames = ["truecommand.jacobcolvin.com"]
        gatewayRef = truenas.tenant.gateways.public
        services.server = {
            name = "truecommand"
            port = 80
        }
        homepage = {
            name = "TrueCommand"
            description = "Centralized TrueNAS Management"
            group = "Apps"
            icon = "truecommand"
        }
    }
}
