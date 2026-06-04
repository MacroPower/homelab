import file
import json

import konfig.files
import konfig.objects

import o11y_seaweedfs_base
import charts.seaweedfs

_baseValues = o11y_seaweedfs_base.app.charts.seaweedfs.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

app = o11y_seaweedfs_base.app | {
    charts.seaweedfs.values = _values | seaweedfs.Values {}

    # Redirect every S3 credential the s3-config ExternalSecret pulls from Doppler
    # to the fake-store "dummy" key so the offline external-secrets provider can
    # answer them. The data entries stay so the ExternalSecret resolves, but the
    # rendered identity config below no longer references them.
    externalSecrets.s3Config.data: {
        MIMIR_S3_ACCESS_KEY.remoteRef.key = "dummy"
        MIMIR_S3_SECRET_KEY.remoteRef.key = "dummy"
        LOKI_S3_ACCESS_KEY.remoteRef.key = "dummy"
        LOKI_S3_SECRET_KEY.remoteRef.key = "dummy"
        TEMPO_S3_ACCESS_KEY.remoteRef.key = "dummy"
        TEMPO_S3_SECRET_KEY.remoteRef.key = "dummy"
    }

    # Collapse the base's three per-app identities (mimir/loki/tempo) into one.
    # With every credential redirected to the same "dummy" value, the base config
    # renders three identities sharing accessKey=dummy, which seaweedfs rejects
    # fatally at S3 init ("duplicate accessKey[dummy]") and the filer crashloops.
    # A single global-action identity with the literal dummy/dummy credentials --
    # the same values every client's s3-config resolves -- makes S3 auth cohere
    # end-to-end offline (the pattern securecodebox/seaweedfs proves with its one
    # identity), and createBuckets still provisions all six buckets.
    externalSecrets.s3Config.target.template.data: {
        seaweedfs_s3_config = json.encode({
            identities = [
                {
                    name = "local"
                    credentials = [
                        {
                            accessKey = "dummy"
                            secretKey = "dummy"
                        }
                    ]
                    actions = [
                        "Admin"
                        "Read"
                        "Write"
                        "List"
                        "Tagging"
                    ]
                }
            ]
        }, indent=2)
    }
}
