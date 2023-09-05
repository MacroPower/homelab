local ingress = import '../../lib/ingress.libsonnet';
local ns = import 'namespace.libsonnet';

local ingressHost = std.extVar('ingressHost');
local ingressAnnotations = std.parseYaml(std.extVar('ingressAnnotations'));


[
  {
    apiVersion: 'traefik.containo.us/v1alpha1',
    kind: 'Middleware',
    metadata: {
      name: 'strip-prefix',
    },
    spec: {
      stripPrefixRegex: {
        regex: [
          '^/api/',
        ],
      },
    },
  },
  {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'Ingress',
    metadata: {
      annotations: ingressAnnotations {
        'traefik.ingress.kubernetes.io/router.middlewares': 'local-ai-strip-prefix@kubernetescrd',
        'gethomepage.dev/description': 'Self-hosted LLMs and more',
        'gethomepage.dev/enabled': 'true',
        'gethomepage.dev/external': 'true',
        'gethomepage.dev/group': 'Apps',
        'gethomepage.dev/icon': 'si-openai',
        'gethomepage.dev/name': 'LocalAI',
        'gethomepage.dev/ping': 'http://local-ai-frontend.local-ai.svc.cluster.local:3000',
        'gethomepage.dev/podSelector': '',
      },
      labels: {},
      name: 'local-ai-frontend-ingress',
    },
    spec: {
      rules: [
        {
          host: ingressHost,
          http: {
            paths: [
              {
                backend: {
                  service: {
                    name: 'local-ai',
                    port: {
                      number: 80,
                    },
                  },
                },
                path: '/api',
                pathType: 'Prefix',
              },
              {
                backend: {
                  service: {
                    name: 'local-ai-frontend',
                    port: {
                      number: 3000,
                    },
                  },
                },
                path: '/',
                pathType: 'Prefix',
              },
            ],
          },
        },
      ],
      tls: [
        {
          hosts: [
            'local-ai',
          ],
        },
      ],
    },
  },
]
