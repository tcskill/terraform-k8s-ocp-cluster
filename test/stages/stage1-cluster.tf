module "dev_cluster" {
  source = "./module"

  cluster_type            = var.cluster_type
  login_user              = var.login_user
  login_password          = var.ibmcloud_api_key
  server_url              = var.server_url
}
