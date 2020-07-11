variable "login_user" {
  type        = string
  description = "The username to log in to openshift"
  default     = "apikey"
}

variable "login_password" {
  type        = string
  description = "The password to log in to openshift"
}

variable "server_url" {
  type        = string
  description = "The url to the server"
}

variable "cluster_type" {
  type        = string
  description = "The type of cluster that should be created (openshift or kubernetes)"
}
