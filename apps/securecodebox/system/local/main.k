import securecodebox_system_main

app = securecodebox_system_main.app | {
    externalSecrets.s3Config.data.S3_ACCESS_KEY.remoteRef.key = "dummy"
    externalSecrets.s3Config.data.S3_SECRET_KEY.remoteRef.key = "dummy"
}
