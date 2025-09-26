import cluster
import starr_qbt_audio_base

app = starr_qbt_audio_base.app | {
    domainName = cluster.DOMAIN_NAME
}
