module "dev_cluster" {
  source = "./module"

  cluster_type            = var.cluster_type
  login_user              = var.login_user
  login_password          = var.login_password
  server_url              = var.server_url
}
