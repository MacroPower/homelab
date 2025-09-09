import models.frontend.common

schema Gateway(common.Metadata):
    group: "gateway.networking.k8s.io"
    kind: "Gateway"
    sectionName?: str
