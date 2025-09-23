resource "auth0_action" "add_roles_to_groups_claim" {
  name    = "Add Roles to Groups Claim"
  runtime = "node22"
  deploy  = true
  code    = <<-EOT
    exports.onExecutePostLogin = async (event, api) => {
      if (event.authorization) {
        // Map Auth0 roles to the groups claim
        const roles = event.authorization.roles || [];
        api.idToken.setCustomClaim(`colvinGroups`, roles);
        api.accessToken.setCustomClaim(`colvinGroups`, roles);
      }
    };
  EOT

  supported_triggers {
    id      = "post-login"
    version = "v3"
  }
}

resource "auth0_trigger_action" "post_login_add_roles_to_groups_claim" {
  trigger   = "post-login"
  action_id = auth0_action.add_roles_to_groups_claim.id
}
