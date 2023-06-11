{
  new(name, namespace, matchLabels, endpoints):: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: name,
      labels: {
        'app.kubernetes.io/name': name,
      },
    },
    spec: {
      endpoints: endpoints,
      namespaceSelector: {
        matchNames: [namespace],
      },
      selector: {
        matchLabels: matchLabels,
      },
    },
  },
}
