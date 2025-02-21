local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='kubelet-csr-approver',
  path='applications/base/kubelet-csr-approver',
  namespace='kube-system',
).withChart(
  name='kubelet-csr-approver',
  repoURL='https://postfinance.github.io/kubelet-csr-approver',
  targetRevision='1.2.6',
  releaseName='kubelet-csr-approver',
  values='values.yaml'
)
