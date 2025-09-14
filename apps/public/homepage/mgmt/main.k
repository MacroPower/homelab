import file
import yaml

import konfig.files
import konfig.objects

import public_homepage_base
import cluster
import charts.homepage

_baseValues = public_homepage_base.app.charts.homepage.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

_settings = public_homepage_base.settings | {
    title = "${cluster.FRIENDLY_NAME} Home"
    background.image = "https://images.unsplash.com/photo-1502790671504-542ad42d5189?auto=format&fit=crop&w=2560&q=80"
}

_widgets = public_homepage_base.widgets
_widgets[1].greeting.text = cluster.FRIENDLY_NAME

app = public_homepage_base.app | {
    domainName = cluster.DOMAIN_NAME
    charts.homepage.values = _values | homepage.Values {
        controllers.app.containers.app.env: {
            HOMEPAGE_ALLOWED_HOSTS = {
                value = "homepage.${domainName}"
            }
        }
    }
    configMaps.homepageConfig.data: {
        "settings.yaml" = yaml.encode(_settings)
        "widgets.yaml" = yaml.encode(_widgets)
    }
}
