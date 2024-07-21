import k8s.api.rbac.v1 as rbacv1
import models.frontend.common
import models.mixins

schema ClusterRoleBinding(common.Metadata):
    """
    subjects: [Subject], default is Undefined, optional
        Subjects holds references to the objects the role applies to.
    roleRef: ClusterRole, default is Undefined, required
        RoleRef can only reference a ClusterRole in the global namespace. If the RoleRef cannot be resolved, the Authorizer must return an error.
    """
    mixin [
        mixins.MetadataMixin
    ]

    namespace = Undefined

    subjects?: [rbacv1.Subject]

    roleRef: rbacv1.RoleRef

    kubernetes: rbacv1.ClusterRoleBinding = rbacv1.ClusterRoleBinding {
        metadata = metadata
        subjects = subjects
        roleRef = roleRef
    }

    assert not namespace, "namespace is not allowed in ClusterRoleBinding"
