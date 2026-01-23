
module "talos_version" {
  source = "./modules/talos-version"

  k8s_version   = null
  talos_version = null
}
# Create a resource that our resources can be triggered by
#  As it appears that modules cannot be used in lifecycle triggers
resource "terraform_data" "talos_version_change" {
  input = module.talos_version.id
}
