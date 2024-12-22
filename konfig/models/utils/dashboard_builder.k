import file
import models.frontend.grafana

DashboardPathBuilder = lambda path: str -> {str:grafana.GrafanaDashboard} {
    _path = path.rstrip("/")
    _ext = ".json"
    _dashboards = file.glob("{}/*{}".format(_path, _ext))
    {
        _f.removeprefix(_path).removesuffix(_ext).strip("/"): grafana.GrafanaDashboard {
            json = file.read(_f)
        }
        for _i, _f in _dashboards
    }
}
