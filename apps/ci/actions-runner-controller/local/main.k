import ci_actions_runner_controller_base

# The gha-runner-scale-set-controller is a single Deployment with no
# Docker-unsafe items (base already pins replicaCount=1, no HW nodeSelectors,
# no storage, no LoadBalancer, no external secrets). Inherit base verbatim; the
# base network policies use the kube-apiserver/kube-dns entities and resolve
# fine on the local cluster.
app = ci_actions_runner_controller_base.app | {}
