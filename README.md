# homelab

IaC and such for my homelab / personal cloud. Mostly k8s via Tanka.

## Getting Started

- Build cluster with TF, add ssh authorized key if needed.
- Run `./connect.sh <server> <port>`
- Create secrets, each environment has its own README that describes what is needed.
- Apply envs as needed `tk apply environments/<name>/ --tla-str "apiServer=https://...:6443"`
  - Note: Always apply `default` before other environments. There are a few races as well that require you to apply twice.

## Todo

1. Remove hardcoded secrets.
2. Add ingress.
3. Remember to do #1 and #2 in order.

## Rules

1. Yaml is to be avoided at all costs.
2. Yaml is to be avoided at ALL costs.
3. Nothing hidden except for secrets.
4. Destroy regularly.

## Security

A major goal of this project is to force myself to use proper security
practices. Ideally I will keep all config / endpoints public, and
allow anyone interested to test things. I may even create some
bounties, who knows. :)

## Related

- https://github.com/MacroPower/dotfiles
- https://github.com/MacroPower/vscode-settings
