import charts.nack.api.v1beta2 as nackv1beta2

streamMainQueue = nackv1beta2.Stream {
    metadata.name = "main-queue"
    spec: {
        account = "opencloud-nats"
        allowRollup = False
        description = "OpenCloud message bus"
        discard = "old"
        duplicateWindow = "2m0s"
        maxAge = "168h"
        maxBytes = -1
        maxConsumers = -1
        maxMsgs = -1
        maxMsgSize = -1
        maxMsgsPerSubject = 0
        name = "main-queue"
        noAck = False
        preventDelete = False
        preventUpdate = False
        replicas = 3
        retention = "limits"
        storage = "file"
        subjects = ["main-queue"]
    }
}

streamKvCacheUserinfo = nackv1beta2.Stream {
    metadata.name = "kv-cache-userinfo"
    spec: {
        account = "opencloud-nats"
        allowRollup = True
        description = "OpenCloud proxy userinfo cache"
        denyDelete = True
        discard = "new"
        duplicateWindow = "10s"
        maxAge = "10s"
        maxBytes = -1
        maxConsumers = -1
        maxMsgs = -1
        maxMsgSize = -1
        maxMsgsPerSubject = 1
        name = "KV_cache-userinfo"
        noAck = False
        allowDirect = False
        preventDelete = False
        preventUpdate = False
        replicas = 3
        retention = "limits"
        storage = "memory"
        subjects = ["$KV.cache-userinfo.>"]
    }
}

streamKvUserlog = nackv1beta2.Stream {
    metadata.name = "kv-userlog"
    spec: {
        account = "opencloud-nats"
        allowRollup = True
        description = "OpenCloud userlog store"
        denyDelete = True
        discard = "new"
        duplicateWindow = "2m0s"
        maxAge = "336h"
        maxBytes = -1
        maxConsumers = -1
        maxMsgs = -1
        maxMsgSize = -1
        maxMsgsPerSubject = 1
        name = "KV_userlog"
        noAck = False
        allowDirect = False
        preventDelete = False
        preventUpdate = False
        replicas = 3
        retention = "limits"
        storage = "file"
        subjects = ["$KV.userlog.>"]
    }
}

streamKvActivitylog = nackv1beta2.Stream {
    metadata.name = "kv-activitylog"
    spec: {
        account = "opencloud-nats"
        allowRollup = True
        description = "OpenCloud activitylog store"
        denyDelete = True
        discard = "new"
        duplicateWindow = "2m0s"
        maxAge = "336h"
        maxBytes = -1
        maxConsumers = -1
        maxMsgs = -1
        maxMsgSize = -1
        maxMsgsPerSubject = 1
        name = "KV_activitylog"
        noAck = False
        allowDirect = False
        preventDelete = False
        preventUpdate = False
        replicas = 3
        retention = "limits"
        storage = "file"
        subjects = ["$KV.activitylog.>"]
    }
}

streamKvPostprocessing = nackv1beta2.Stream {
    metadata.name = "kv-postprocessing"
    spec: {
        account = "opencloud-nats"
        allowRollup = True
        description = "OpenCloud postprocessing store"
        denyDelete = True
        discard = "new"
        duplicateWindow = "2m0s"
        maxAge = "168h"
        maxBytes = -1
        maxConsumers = -1
        maxMsgs = -1
        maxMsgSize = -1
        maxMsgsPerSubject = 1
        name = "KV_postprocessing"
        noAck = False
        allowDirect = False
        preventDelete = False
        preventUpdate = False
        replicas = 3
        retention = "limits"
        storage = "file"
        subjects = ["$KV.postprocessing.>"]
    }
}

streamKvIdsStorageUsers = nackv1beta2.Stream {
    metadata.name = "kv-ids-storage-users"
    spec: {
        account = "opencloud-nats"
        allowRollup = True
        description = "OpenCloud storageusers id cache"
        denyDelete = True
        discard = "new"
        duplicateWindow = "2m0s"
        maxAge = "24h"
        maxBytes = -1
        maxConsumers = -1
        maxMsgs = -1
        maxMsgSize = -1
        maxMsgsPerSubject = 1
        name = "KV_ids-storage-users"
        noAck = False
        allowDirect = False
        preventDelete = False
        preventUpdate = False
        replicas = 3
        retention = "limits"
        storage = "memory"
        subjects = ["$KV.ids-storage-users.>"]
    }
}

streamKvStorageUsers = nackv1beta2.Stream {
    metadata.name = "kv-storage-users"
    spec: {
        account = "opencloud-nats"
        allowRollup = True
        description = "OpenCloud storageusers cache"
        denyDelete = True
        discard = "new"
        duplicateWindow = "2m0s"
        maxAge = "24h"
        maxBytes = -1
        maxConsumers = -1
        maxMsgs = -1
        maxMsgSize = -1
        maxMsgsPerSubject = 1
        name = "KV_storage-users"
        noAck = False
        allowDirect = False
        preventDelete = False
        preventUpdate = False
        replicas = 3
        retention = "limits"
        storage = "memory"
        subjects = ["$KV.storage-users.>"]
    }
}

streamKvEventhistory = nackv1beta2.Stream {
    metadata.name = "kv-eventhistory"
    spec: {
        account = "opencloud-nats"
        allowRollup = True
        description = "OpenCloud userlog store"
        denyDelete = True
        discard = "new"
        duplicateWindow = "2m0s"
        maxAge = "336h"
        maxBytes = -1
        maxConsumers = -1
        maxMsgs = -1
        maxMsgSize = -1
        maxMsgsPerSubject = 1
        name = "KV_eventhistory"
        noAck = False
        allowDirect = False
        preventDelete = False
        preventUpdate = False
        replicas = 3
        retention = "limits"
        storage = "file"
        subjects = ["$KV.eventhistory.>"]
    }
}

streamKvServiceRegistry = nackv1beta2.Stream {
    metadata.name = "kv-service-registry"
    spec: {
        account = "opencloud-nats"
        allowRollup = True
        description = "OpenCloud service registry"
        denyDelete = True
        discard = "new"
        duplicateWindow = "30s"
        maxAge = "30s"
        maxBytes = -1
        maxConsumers = -1
        maxMsgs = -1
        maxMsgSize = -1
        maxMsgsPerSubject = 1
        name = "KV_service-registry"
        noAck = False
        allowDirect = False
        preventDelete = False
        preventUpdate = False
        replicas = 3
        retention = "limits"
        storage = "memory"
        subjects = ["$KV.service-registry.>"]
    }
}

streamKvSettingsCache = nackv1beta2.Stream {
    metadata.name = "kv-settings-cache"
    spec: {
        account = "opencloud-nats"
        allowRollup = True
        description = "OpenCloud settings cache"
        denyDelete = True
        discard = "new"
        duplicateWindow = "2m0s"
        maxAge = "10m0s"
        maxBytes = -1
        maxConsumers = -1
        maxMsgs = -1
        maxMsgSize = -1
        maxMsgsPerSubject = 1
        name = "KV_settings-cache"
        noAck = False
        allowDirect = False
        preventDelete = False
        preventUpdate = False
        replicas = 3
        retention = "limits"
        storage = "memory"
        subjects = ["$KV.settings-cache.>"]
    }
}

streamKvStorageSystem = nackv1beta2.Stream {
    metadata.name = "kv-storage-system"
    spec: {
        account = "opencloud-nats"
        allowRollup = True
        description = "OpenCloud storagesystem cache"
        denyDelete = True
        discard = "new"
        duplicateWindow = "2m0s"
        maxAge = "24h"
        maxBytes = -1
        maxConsumers = -1
        maxMsgs = -1
        maxMsgSize = -1
        maxMsgsPerSubject = 1
        name = "KV_storage-system"
        noAck = False
        allowDirect = False
        preventDelete = False
        preventUpdate = False
        replicas = 3
        retention = "limits"
        storage = "memory"
        subjects = ["$KV.storage-system.>"]
    }
}

streamKvCacheRoles = nackv1beta2.Stream {
    metadata.name = "kv-cache-roles"
    spec: {
        account = "opencloud-nats"
        allowRollup = True
        description = "OpenCloud graph roles cache"
        denyDelete = True
        discard = "new"
        duplicateWindow = "2m0s"
        maxAge = "24h"
        maxBytes = -1
        maxConsumers = -1
        maxMsgs = -1
        maxMsgSize = -1
        maxMsgsPerSubject = 1
        name = "KV_cache-roles"
        noAck = False
        allowDirect = False
        preventDelete = False
        preventUpdate = False
        replicas = 3
        retention = "limits"
        storage = "memory"
        subjects = ["$KV.cache-roles.>"]
    }
}

streamKvProxy = nackv1beta2.Stream {
    metadata.name = "kv-proxy"
    spec: {
        account = "opencloud-nats"
        allowRollup = True
        description = "OpenCloud ocs and proxy signing keys"
        denyDelete = True
        discard = "new"
        duplicateWindow = "2m0s"
        maxAge = "24h"
        maxBytes = -1
        maxConsumers = -1
        maxMsgs = -1
        maxMsgSize = -1
        maxMsgsPerSubject = 1
        name = "KV_proxy"
        noAck = False
        allowDirect = False
        preventDelete = False
        preventUpdate = False
        replicas = 3
        retention = "limits"
        storage = "memory"
        subjects = ["$KV.proxy.>"]
    }
}

streamKvOpencloudPkg = nackv1beta2.Stream {
    metadata.name = "kv-opencloud-pkg"
    spec: {
        account = "opencloud-nats"
        allowRollup = True
        description = "OpenCloud settings roles cache"
        denyDelete = True
        discard = "new"
        duplicateWindow = "2m0s"
        maxAge = "24h"
        maxBytes = -1
        maxConsumers = -1
        maxMsgs = -1
        maxMsgSize = -1
        maxMsgsPerSubject = 1
        name = "KV_opencloud-pkg"
        noAck = False
        allowDirect = False
        preventDelete = False
        preventUpdate = False
        replicas = 3
        retention = "limits"
        storage = "memory"
        subjects = ["$KV.opencloud-pkg.>"]
    }
}
