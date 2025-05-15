MetadataBuilder = lambda metadata -> {str:} {
    {
        name: metadata?.name
        namespace: metadata?.namespace
        labels: metadata?.labels
        annotations: metadata?.annotations
    }
}
