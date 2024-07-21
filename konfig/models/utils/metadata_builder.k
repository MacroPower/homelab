import models.metadata

MetadataBuilder = lambda config -> {str:} {
    {
        name: config?.name
        labels: config?.labels
        annotations: config?.annotations
    }
}
