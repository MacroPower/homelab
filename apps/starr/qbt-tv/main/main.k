import cluster
import starr_qbt_tv_base

app = starr_qbt_tv_base.app | {
    domainName = cluster.DOMAIN_NAME
}
