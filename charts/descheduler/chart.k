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
    values : Values | any, optional
    chart : str, required, default is "descheduler"
    repoURL : str, required, default is "https://kubernetes-sigs.github.io/descheduler/"
    targetRevision : str, optional, default is "0.30.1"
    """
    values?: Values | any
    chart: str = "descheduler"
    repoURL: str = "https://kubernetes-sigs.github.io/descheduler/"
    targetRevision?: str = "0.30.1"

