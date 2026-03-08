locals {
  # A matrix of project_names and environment_names
  projects = merge([
    for project_name in var.project_names : {
      for environment_name in var.environment_names :
      "${project_name}-${environment_name}" => {
        project_name     = project_name
        environment_name = environment_name
      }
    }
  ]...)
}
