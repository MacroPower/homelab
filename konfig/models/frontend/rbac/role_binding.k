import k8s.api.rbac.v1 as rbacv1
import models.frontend.common

schema RoleBinding(common.Metadata):
    """
    Attributes
    ----------
    subjects: [Subject], default is Undefined, optional
        Subjects holds references to the objects the role applies to.
    roleRef: RoleRef, default is Undefined, required
        RoleRef can only reference a ClusterRole in the global namespace. If the RoleRef cannot be resolved, the Authorizer must return an error.
    """
    subjects?: [rbacv1.Subject]
    roleRef: rbacv1.RoleRef
