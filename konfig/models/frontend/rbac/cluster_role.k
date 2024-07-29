import k8s.api.rbac.v1 as rbacv1
import models.frontend.common

schema ClusterRole(common.Metadata):
    """
    Attributes
    ----------
    rules: [PolicyRule], default is Undefined, optional
        Rules holds all the PolicyRules for this ClusterRole
    aggregationRule: AggregationRule, default is Undefined, optional
        AggregationRule is an optional field that describes how to build the Rules for this ClusterRole. If AggregationRule is set, then the Rules are controller managed and direct changes to Rules will be stomped by the controller.
    """
    namespace = Undefined
    rules?: [rbacv1.PolicyRule]
    aggregationRule?: rbacv1.AggregationRule

    getRef: () -> rbacv1.RoleRef = lambda -> rbacv1.RoleRef {
        {
            apiGroup = "rbac.authorization.k8s.io"
            kind = "ClusterRole"
            name = name
        }
    }

    assert not namespace, "namespace is not allowed in ClusterRole"
