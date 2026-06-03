import file

import konfig.files
import konfig.objects

import truenas_restic_base
import cluster
import charts.restic

_baseValues = truenas_restic_base.app.charts.restic.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

# Docker-safe local overlay:
# - Drop the knas01 hostname nodeSelector and the NAS hostPath backup repo from
#   main/ (not inherited here); the repo data is served from a small
#   openebs-hostpath PVC instead (see values.yaml).
# - The restic-credentials ExternalSecret reads RESTIC_USERNAME/RESTIC_PASSWORD
#   from Doppler in prod; offline the fake ClusterSecretStore only serves
#   "dummy", so point every remoteRef.key at "dummy". The rendered .htpasswd is
#   therefore the degraded constant dummy:bcrypt(dummy) -- auth is non-functional
#   locally but the pod starts and the REST server stays healthy.
app = truenas_restic_base.app | {
    domainName = cluster.DOMAIN_NAME
    externalSecrets.htpasswd.data.RESTIC_USERNAME.remoteRef.key = "dummy"
    externalSecrets.htpasswd.data.RESTIC_PASSWORD.remoteRef.key = "dummy"
    charts.restic.values = _values | restic.Values {}
}
