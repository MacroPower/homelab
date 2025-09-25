import cluster
import starr_qbt_movies_base

app = starr_qbt_movies_base.app | {
    domainName = cluster.DOMAIN_NAME
}
