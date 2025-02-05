local app = import '../../lib/app.libsonnet';
local ns = import 'namespace.libsonnet';

app.new(
  name='securecodebox-addons',
  path='applications/base/securecodebox-addons',
  namespace=ns.metadata.name,
).withChart(
  name='auto-discovery-kubernetes',
  repoURL='https://charts.securecodebox.io/',
  targetRevision='4.5.0',
  releaseName='securecodebox-auto-discovery-kubernetes',
  values='values-auto-discovery-kubernetes.yaml'
).withChart(
  name='cascading-scans',
  repoURL='https://charts.securecodebox.io/',
  targetRevision='4.5.0',
  releaseName='securecodebox-cascading-scans',
  values='values-cascading-scans.yaml'
).withChart(
  name='nmap',
  repoURL='https://charts.securecodebox.io/',
  targetRevision='4.5.0',
  releaseName='securecodebox-nmap',
  values='values-nmap.yaml'
).withChart(
  name='nmap',
  repoURL='https://charts.securecodebox.io/',
  targetRevision='4.5.0',
  releaseName='securecodebox-nmap-privileged',
  values='values-nmap-privileged.yaml'
).withChart(
  name='nuclei',
  repoURL='https://charts.securecodebox.io/',
  targetRevision='4.5.0',
  releaseName='securecodebox-nuclei',
  values='values-nuclei.yaml'
).withChart(
  name='persistence-defectdojo',
  repoURL='https://charts.securecodebox.io/',
  targetRevision='4.5.0',
  releaseName='securecodebox-persistence-defectdojo',
  values='values-persistence-defectdojo.yaml'
).withChart(
  name='ssh-audit',
  repoURL='https://charts.securecodebox.io/',
  targetRevision='4.5.0',
  releaseName='securecodebox-ssh-audit',
  values='values-ssh-audit.yaml'
).withChart(
  name='zap',
  repoURL='https://charts.securecodebox.io/',
  targetRevision='4.13.0',
  releaseName='securecodebox-zap',
  values='values-zap.yaml'
)
