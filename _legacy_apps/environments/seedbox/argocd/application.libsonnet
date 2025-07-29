local app = import '../../../base/argocd/application.libsonnet';

app.withChartValues(|||
  configs:
    cm:
      url: https://argocd.seedbox.macro.network
      dex.config: |
        connectors:
          - name: authentik
            id: authentik
            type: oauth
            config:
              tokenURL: "http://authentik-server.authentik.svc/application/o/token/"
              authorizationURL: "https://authentik.seedbox.macro.network/application/o/authorize/"
              userInfoURL: "http://authentik-server.authentik.svc/application/o/userinfo/"
              clientID: $dex.authentik.clientID
              clientSecret: $dex.authentik.clientSecret
              insecureSkipVerify: false
              insecureEnableGroups: true
              scopes:
                - openid
                - profile
                - email
              userIDKey: sub
              claimMapping:
                userNameKey: name

  controller:
    replicas: 2

  server:
    replicas: 2

  repoServer:
    replicas: 1

  applicationSet:
    replicas: 1
|||)
