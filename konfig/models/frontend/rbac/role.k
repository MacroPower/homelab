import k8s.api.rbac.v1 as rbacv1
import models.frontend.common

schema Role(common.Metadata):
    """
    Attributes
    ----------
    rules: [PolicyRule], default is Undefined, optional
        Rules holds all the PolicyRules for this ClusterRole
    """
    rules?: [rbacv1.PolicyRule]
