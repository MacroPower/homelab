# Migrating a Terraform Cloud Workspace to Spacelift

How to move a Terraform Cloud workspace into a Spacelift-managed stack with OpenTofu.

## Prerequisites

- `spacectl` authenticated with Spacelift
- `terraform` CLI authenticated with Terraform Cloud
- Access to Doppler `spacelift/root` config

## Steps

### 1. Export state from Terraform Cloud

While the workspace still has the `terraform.cloud` backend configured:

```bash
cd terraform/<module>
terraform state pull > <module>.tfstate
```

### 2. Move the module to `tofu/`

```bash
mkdir -p tofu/<module>
# Move .tf files and any scripts (do NOT copy .terraform.lock.hcl)
mv terraform/<module>/*.tf terraform/<module>/*.sh tofu/<module>/
rm -r terraform/<module>
```

### 3. Remove the Terraform Cloud backend

Delete `main.tf` if it only contains the `terraform.cloud` block. You just need the `terraform {}` block with `required_providers` in `providers.tf`. Spacelift injects its own HTTP backend at runtime.

### 4. Create Doppler service tokens

Add scoped tokens to the `spacelift/root` Doppler config for each Doppler provider alias the module uses. For example, a module with three aliases needs three tokens:

| Doppler Key           | Scoped To                    |
|-----------------------|------------------------------|
| `DOPPLER_TOKEN_FOO`   | project `foo`, config `bar`  |

### 5. Add the Spacelift stack

In `tofu/spacelift/main.tf`, add a space, stack, and environment variables:

```hcl
resource "spacelift_space" "<module>" {
  name             = "<module>"
  parent_space_id  = "root"
  description      = "Space for <module> infrastructure"
  inherit_entities = true
}

resource "spacelift_stack" "<module>" {
  name        = "<module>"
  description = "<description>"

  space_id                = spacelift_space.<module>.id
  project_root            = "tofu/<module>"
  repository              = "homelab"
  branch                  = "main"
  autodeploy              = true
  manage_state            = true
  terraform_workflow_tool = "OPEN_TOFU"
}

resource "spacelift_environment_variable" "<module>_doppler_token" {
  stack_id   = spacelift_stack.<module>.id
  name       = "TF_VAR_doppler_token"
  value      = data.doppler_secrets.spacelift.map.DOPPLER_TOKEN_<MODULE>
  write_only = true
}
```

Repeat `spacelift_environment_variable` for each Doppler token the module needs.

### 6. Deploy the Spacelift stack

Push the code changes and apply the spacelift root stack to create the new stack:

```bash
spacectl stack deploy --id spacelift
```

### 7. Import state

Mount the exported state file, push it into the Spacelift-managed backend, then clean up:

```bash
# Mount the state file on the stack
spacectl stack environment mount --id <module> --write-only <module>.tfstate <module>.tfstate

# Push state into the Spacelift backend
spacectl stack task --id <module> --tail 'tofu state push -force /mnt/workspace/<module>.tfstate'

# Remove the mounted file
spacectl stack environment delete --id <module> <module>.tfstate
```

You'll see "Failed to load plugin schemas" errors after the push. Don't worry about them. The push itself succeeds ("Custom task performed successfully"). The schema errors come from Spacelift's post-task analysis, which runs without provider credentials and can't resolve the schemas.

### 8. Verify

Trigger a tracked run and confirm a clean plan with no changes:

```bash
spacectl stack deploy --id <module>
```

### 9. Clean up

- Delete the exported `.tfstate` file locally
- Decommission the workspace in Terraform Cloud
