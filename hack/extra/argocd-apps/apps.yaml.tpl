apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/MacroPower/homelab'
    path: applications/environments/${environment_name}
    directory:
      exclude: spec.json
      jsonnet:
        libs:
          - applications/vendor
          - applications/lib
    targetRevision: main
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: argocd
  syncPolicy:
    automated:
      prune: false
      selfHeal: false
