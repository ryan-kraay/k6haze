locals {
  # A matrix of project_names and environment_names
  _projects = merge([
    for project_name in var.project_names : {
      for environment_name in var.environment_names :
      "${environment_name}-${project_name}" => {
        project_name     = project_name
        environment_name = environment_name
      }
    }
  ]...)

  # Future-proofing, allows us to (in theory) seperate
  #  specs from terraform.
  terraform_projects = local._projects
  spec_projects      = local._projects

  # All the projects that need AGE keys
  age_projects = merge(
    { for k, v in local.terraform_projects : "${k}-terraform" => merge(v, { relpath = "" }) },
    { for k, v in local.spec_projects : "${k}-spec" => merge(v, { relpath = "/spec" }) }
  )
}
