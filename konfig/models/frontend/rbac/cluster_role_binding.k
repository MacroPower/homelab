import k8s.api.rbac.v1 as rbacv1
import models.frontend.common

schema ClusterRoleBinding(common.Metadata):
    """
    Attributes
    ----------
    subjects: [Subject], default is Undefined, optional
        Subjects holds references to the objects the role applies to.
    roleRef: ClusterRole, default is Undefined, required
        RoleRef can only reference a ClusterRole in the global namespace. If the RoleRef cannot be resolved, the Authorizer must return an error.
    """
    namespace = Undefined
    subjects?: [rbacv1.Subject]
    roleRef: rbacv1.RoleRef

    assert not namespace, "namespace is not allowed in ClusterRoleBinding"
