import models.metadata

MetadataBuilder = lambda config -> {str:} {
    {
        name: config?.name
        namespace: config?.namespace
        labels: config?.labels
        annotations: config?.annotations
    }
}
