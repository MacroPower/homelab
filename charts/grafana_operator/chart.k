"""
This file was generated by the KCL auto-gen tool. DO NOT EDIT.
Editing this file might prove futile when you re-run the KCL auto-gen generate command.
"""
import helm

schema Chart(helm.Chart):
    r"""
    All possible chart configuration, inheriting from `helm.Chart(helm.ChartBase)`.

    Attributes
    ----------
    values : Values | any, optional, default is {rbac = {create = False}}
    chart : str, required, default is "grafana-operator"
    repoURL : str, required, default is "oci://ghcr.io/grafana/helm-charts/grafana-operator"
    targetRevision : str, optional, default is "v5.16.0"
    """
    values?: Values | any = {
        rbac = {create = False}
    }
    chart: str = "grafana-operator"
    repoURL: str = "oci://ghcr.io/grafana/helm-charts/grafana-operator"
    targetRevision?: str = "v5.16.0"

