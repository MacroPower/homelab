import k8s.api.rbac.v1 as rbacv1
import models.utils
import models.resource
import models.protocol

mixin RoleBindingMixin for protocol.AppProtocol:
    if config.roleBindings:
        kubernetes: resource.ResourceMapping {
            RoleBindings = [rbacv1.RoleBinding {
                metadata: utils.MetadataBuilder(_c)
                roleRef: _c.roleRef
                subjects: [
                    {
                        kind: _s.kind
                        name: _s.name
                        namespace: _s?.namespace or config.namespace
                    }
                    for _s in _c.subjects
                ]
            } for _i, _c in config.roleBindings]
        }

mixin ClusterRoleBindingMixin for protocol.AppProtocol:
    if config.clusterRoleBindings:
        kubernetes: resource.ResourceMapping {
            ClusterRoleBindings = [rbacv1.ClusterRoleBinding {
                metadata: utils.MetadataBuilder(_c)
                roleRef: _c.roleRef
                subjects: [
                    {
                        kind: _s.kind
                        name: _s.name
                        namespace: _s?.namespace or config.namespace
                    }
                    for _s in _c.subjects
                ]
            } for _i, _c in config.clusterRoleBindings]
        }

mixin RoleMixin for protocol.AppProtocol:
    if config.roles:
        kubernetes: resource.ResourceMapping {
            Roles = [rbacv1.Role {
                metadata: utils.MetadataBuilder(_c)
                rules: _c.rules
            } for _i, _c in config.roles]
        }

mixin ClusterRoleMixin for protocol.AppProtocol:
    if config.clusterRoles:
        kubernetes: resource.ResourceMapping {
            ClusterRoles = [rbacv1.ClusterRole {
                metadata: utils.MetadataBuilder(_c)
                rules: _c.rules
            } for _i, _c in config.clusterRoles]
        }
