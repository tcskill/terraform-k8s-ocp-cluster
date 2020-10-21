variable "cluster_type" {
  type        = string
  description = "The type of cluster into which the toolkit will be installed (openshift or ocp3 or ocp4)"
  default     = "ocp4"
}

variable "login_user" {
  type        = string
  description = "The username to log in to openshift"
  default     = ""
}

variable "login_password" {
  type        = string
  description = "The password to log in to openshift"
  default     = ""
}

variable "login_token" {
  type        = string
  description = "The token to log in to openshift"
  default     = ""
}

variable "server_url" {
  type        = string
  description = "The url to the server"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the IBM Cloud resource group where the cluster will be created/can be found."
  default     = "N/A"
}

variable "cluster_region" {
  type        = string
  description = "The IBM Cloud region where the cluster will be/has been installed."
  default     = "N/A"
}

variable "registry_namespace" {
  type        = string
  description = "The namespace that will be created in the IBM Cloud image registry. If not provided the value will default to the resource group"
  default     = "default"
}

variable "ingress_subdomain" {
  type        = string
  description = "The ROUTER_CANONICAL_HOSTNAME for the cluster"
  default     = ""
}

variable "gitops_dir" {
  type        = string
  description = "Directory where the gitops repo content should be written"
  default     = ""
}
