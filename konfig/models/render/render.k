import models.frontend
import models.frontend.rbac
import models.backend
import models.resource
import models.metadata as kmd
import k8s.api.core.v1 as corev1

import manifests

# Minimize container resource *requests* so workloads can be packed onto the
# single-node local test cluster. Only `resources.requests` is overridden, to a
# minimal `cpu = "1m", memory = "1Mi"`; `resources.limits` is left exactly as
# rendered. Keeping limits preserves the node's protection against runaway pods.
# Requests are set explicitly rather than removed because Kubernetes defaults a
# container's requests up to its limits when requests are absent -- dropping
# requests would silently re-impose the (large) production limits as requests.
# A container with no `resources` (or an empty `{}`) is left untouched: it is
# BestEffort today and stays BestEffort.
#
# The override is a nested-path union, `c | {resources.requests = {...}}`, which
# REPLACES the `requests` map wholesale (verified empirically): any extended
# resource a container might have requested -- e.g. `nvidia.com/gpu` -- is
# dropped along with the original cpu/memory, leaving only the two minimal keys,
# so nothing lingers to block scheduling. No app here requests extended
# resources today, but replace is the safe semantics regardless.
#
# KCL lambdas cannot recurse, so this walks a fixed set of known workload paths
# rather than the whole tree. Resources that are not workloads (ConfigMaps,
# Secrets, ClusterRoles with their own `.rules[].resources`, etc.) match no path
# and pass through byte-for-byte.
#
# Each navigation hop guards with `"key" in obj and obj.key` rather than `?.`:
# rendered resources are a mix of plain dicts and typed schemas (the kclipper
# `Resource` for helm output, CiliumNetworkPolicy specs, the CNPG `Cluster`,
# PodSpec, ...). On a schema, `?.` over an *undeclared* attribute raises (it does
# not yield None), and `in` reports *declared* attributes as present even when
# their value is `Undefined` -- so `in` alone would then try to descend into
# `Undefined` and crash. The paired truthiness check (`obj.key`) short-circuits
# that: it is only reached once the key is known-present, and it is false for an
# absent/Undefined/empty value -- which is also exactly how a BestEffort
# container (no/empty `resources`) is recognized and skipped.

__MINIMAL_REQUESTS = {cpu = "1m", memory = "1Mi"}

# Override `resources.requests` on every container that carries a truthy
# `resources` block; leave BestEffort containers (no/empty `resources`) alone.
__minimizeContainerRequests = lambda containers {
    [
        c | {resources.requests = __MINIMAL_REQUESTS} if "resources" in c and c.resources else c
        for c in containers
    ]
}

# Minimize a PodSpec's containers/initContainers requests in place.
__minimizePodTemplateRequests = lambda podSpec {
    _podSpec = podSpec
    if "containers" in _podSpec and _podSpec.containers:
        _podSpec |= {containers = __minimizeContainerRequests(_podSpec.containers)}
    if "initContainers" in _podSpec and _podSpec.initContainers:
        _podSpec |= {initContainers = __minimizeContainerRequests(_podSpec.initContainers)}
    _podSpec
}

# Minimize the request side of every `resources` block on a single rendered
# workload manifest. Returns non-workload resources unchanged.
__minimizeWorkloadRequests = lambda r {
    _r = r
    if "spec" in _r and _r.spec:
        _spec = _r.spec
        # Deployment, StatefulSet, DaemonSet, Job, ReplicaSet, bare Pod template.
        if "template" in _spec and _spec.template and "spec" in _spec.template and _spec.template.spec:
            _r |= {spec.template.spec = __minimizePodTemplateRequests(_spec.template.spec)}
        # CronJob nests its PodSpec one level deeper.
        if "jobTemplate" in _spec and _spec.jobTemplate and "spec" in _spec.jobTemplate and _spec.jobTemplate.spec \
        and "template" in _spec.jobTemplate.spec and _spec.jobTemplate.spec.template \
        and "spec" in _spec.jobTemplate.spec.template and _spec.jobTemplate.spec.template.spec:
            _r |= {spec.jobTemplate.spec.template.spec = __minimizePodTemplateRequests(_spec.jobTemplate.spec.template.spec)}
        # Bare Pod carries its containers directly on `spec`.
        if _r.kind == "Pod" and "containers" in _spec and _spec.containers:
            _r |= {spec.containers = __minimizeContainerRequests(_spec.containers)}
        if _r.kind == "Pod" and "initContainers" in _spec and _spec.initContainers:
            _r |= {spec.initContainers = __minimizeContainerRequests(_spec.initContainers)}
        # CNPG Cluster sets pod resources on `spec.resources`.
        if _r.kind == "Cluster" and str(_r.apiVersion or "").startswith("postgresql.cnpg.io") \
        and "resources" in _spec and _spec.resources:
            _r |= {spec.resources.requests = __MINIMAL_REQUESTS}
        # Envoy Gateway's EnvoyProxy sets them on the deployment container.
        if _r.kind == "EnvoyProxy" and "provider" in _spec and _spec.provider \
        and "kubernetes" in _spec.provider and _spec.provider.kubernetes \
        and "envoyDeployment" in _spec.provider.kubernetes and _spec.provider.kubernetes.envoyDeployment \
        and "container" in _spec.provider.kubernetes.envoyDeployment and _spec.provider.kubernetes.envoyDeployment.container \
        and "resources" in _spec.provider.kubernetes.envoyDeployment.container \
        and _spec.provider.kubernetes.envoyDeployment.container.resources:
            _r |= {spec.provider.kubernetes.envoyDeployment.container.resources.requests = __MINIMAL_REQUESTS}
    _r
}

# Apply the request-minimizing transform to a resource only when the render
# context asks for it; otherwise the resource is returned exactly as rendered.
# The truthiness guard on `r` passes deleted entries through untouched: an
# overlay removes an inherited extraResource by setting it to `Undefined`, and
# that placeholder still flows through the extraResources comprehension.
__maybeMinimizeRequests = lambda r {
    _r = r
    if kmd.context.minimizeRequests and r:
        _r = __minimizeWorkloadRequests(_r)
    _r
}

# predefined functions
# lambda: check if two k8s resources are identical
checkIdentical = lambda a, b {
    _a_namespace = a.metadata.namespace or "default"
    _b_namespace = b.metadata.namespace or "default"

    identical = a.apiVersion == b.apiVersion \
    and a.kind == b.kind \
    and a.metadata.name == b.metadata.name \
    and _a_namespace == _b_namespace
}

# Output the resource
manifestsResourceMap = lambda resource_map: {str: []} {
    # Convert resource map into a resource list
    _resource_list = [res_list for _, res_list in resource_map]
    # Use `sum` function to flatten the resource list
    _resource_list = sum(_resource_list, [])
    manifests.yaml_stream(_resource_list)
}

# lambda: remove duplicated resource
remove_duplicated_iter = lambda data: [], func {
    [data[i] for i in range(len(data)) if sum([1 for jdata in data[i+1:] if func(data[i], jdata)]) == 0]
}

__renderTenantFrontendInstances__ = [inst for inst in frontend.Tenant.instances() if typeof(inst) == "Tenant"]
__renderTenantBackendInstances__ = [backend.TenantBackend(inst) for inst in __renderTenantFrontendInstances__]
__renderSharedAppFrontendInstances__ = [inst for inst in frontend.SharedApp.instances() if typeof(inst) == "SharedApp"]
__renderSharedAppBackendInstances__ = [backend.SharedAppBackend(inst) for inst in __renderSharedAppFrontendInstances__]
__renderAppFrontendInstances__ = [inst for inst in frontend.App.instances() if typeof(inst) == "App"]
__renderAppBackendInstances__ = [backend.AppBackend(inst) for inst in __renderAppFrontendInstances__]
__appExtraResources = [__maybeMinimizeRequests(v) for s in __renderAppFrontendInstances__ for k, v in s.extraResources]

__renderBackendInstances__ = [
    *__renderAppBackendInstances__,
    *__renderSharedAppBackendInstances__,
    *__renderTenantBackendInstances__
]

# rbac map, kind to resource array
__rbac_map__: resource.ResourceMapping = {
    if len(rbac.ClusterRoleBinding.instances()) > 0:
        ClusterRoleBinding += [r.kubernetes for r in rbac.ClusterRoleBinding.instances()]
    if len(rbac.ClusterRole.instances()) > 0:
        ClusterRole += [r.kubernetes for r in rbac.ClusterRole.instances()]
    if len(rbac.RoleBinding.instances()) > 0:
        RoleBinding += [r.kubernetes for r in rbac.RoleBinding.instances()]
    if len(rbac.Role.instances()) > 0:
        Role += [r.kubernetes for r in rbac.Role.instances()]
}

# k8s
__k8s__: resource.ResourceMapping = {
    Service += corev1.Service.instances()
    ServiceAccount += corev1.ServiceAccount.instances()
}

# merge resource map
__array_of_resource_map___: [resource.ResourceMapping] = [
    _inst?.kubernetes for _inst in __renderBackendInstances__ if _inst?.kubernetes
] | [__rbac_map__] | [__k8s__]

__resource_map_original___: {str: []} = {
    _kind += [r for key, r in _res] \
        for _index, _resource_map in __array_of_resource_map___  \
            for _kind, _res in _resource_map if _kind not in ["__settings__"]
}

# remove duplicates
__resource_map___: {str: []} = {kind = remove_duplicated_iter(res_list, checkIdentical) for kind, res_list in __resource_map_original___}

# kubernetes id: apiVersion:Kind:Namespace:Name
getId = lambda _resource {
    _resource.apiVersion + ":" + _resource.kind + ":" + (_resource.metadata.namespace + ":" if _resource.metadata.namespace else "") + _resource.metadata.name
}

_output = {
    _kind: [__maybeMinimizeRequests(_resource) for _resource in _res] \
        for _kind, _res in __resource_map___
} | {
    __extra: __appExtraResources
}
manifestsResourceMap(_output)
