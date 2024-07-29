import models.frontend.common

schema Chart(common.Metadata):
    """Helm chart resource.

    Attributes
    ----------
    repoURL: {str:str}, default is Undefined, optional.
        The URL of the chart repository.
    targetRevision: str, default is Undefined, optional.
        Version of the chart to install.
    selfHeal: bool, default is True, optional.
        Set to `False` to disable self-heal automation.
    prune: bool, default is True, optional.
        Set to `False` to skip adding finalizers, so that resources are orphaned
        when the chart is uninstalled.
    skipCRDs: bool, default is False, optional.
        Set to `True` to skip installing CRDs.
    values: str | any, default is {}, optional.
        Chart values, can be provided as a string or an arbitrary object.

    Examples
    --------
    charts.mychart = Chart {
        name = "my-chart"
        repoURL = "https://jacobcolvin.com/helm-charts"
        targetRevision = "1.0.0"
        values = {
            foo = "bar"
            bar = "foo"
        }
    }
    """
    repoURL: str
    targetRevision: str
    selfHeal?: bool = True
    prune?: bool = True
    skipCRDs?: bool = False
    values?: str | any = {}
