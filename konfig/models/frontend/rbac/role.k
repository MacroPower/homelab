import k8s.api.rbac.v1 as rbacv1
import models.frontend.common
import models.mixins

schema Role(common.Metadata):
    """
    rules: [PolicyRule], default is Undefined, optional
        Rules holds all the PolicyRules for this ClusterRole
    """
    mixin [
        mixins.MetadataMixin
    ]

    rules?: [rbacv1.PolicyRule]

    kubernetes: rbacv1.Role = rbacv1.Role {
        metadata = metadata
        rules = rules
    }
