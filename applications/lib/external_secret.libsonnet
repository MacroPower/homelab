{
  data(key, remoteKey=''):: {
    secretKey: key,
    remoteRef: {
      key: if remoteKey == '' then key else remoteKey,
    },
  },

  new(name, namespace, secretStore='default', data=[]):: {
    apiVersion: 'external-secrets.io/v1beta1',
    kind: 'ExternalSecret',
    metadata: {
      name: name,
      namespace: namespace,
    },
    spec: {
      secretStoreRef: {
        kind: 'ClusterSecretStore',
        name: secretStore,
      },
      target: {
        name: name,
      },
      data: data,
    },

    withTemplate(data, type=''):: self {
      spec+: {
        target+: {
          template: {
            type: type,
            engineVersion: 'v2',
            data: data,
          },
        },
      },
    },
  },
}
