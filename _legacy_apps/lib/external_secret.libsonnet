{
  data(key, remoteKey='', decodingStrategy=''):: {
    secretKey: key,
    remoteRef: {
      key: if remoteKey == '' then key else remoteKey,
      [if decodingStrategy != '' then 'decodingStrategy']: decodingStrategy,
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
            [if type != '' then 'type']: type,
            engineVersion: 'v2',
            data: data,
          },
        },
      },
    },
  },
}
