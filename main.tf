provider "helm" {
  version = ">= 1.1.1"

  kubernetes {
    config_path = local.cluster_config
  }
}

provider "null" {
}

locals {
  cluster_config_dir    = pathexpand("~/.kube")
  cluster_config        = "${local.cluster_config_dir}/config"
  config_namespace      = "default"
  ibmcloud_apikey_chart = "${path.module}/charts/ibmcloud"
  cluster_name          = "crc"
  tls_secret_file       = ""
  tmp_dir               = "${path.cwd}/.tmp"
  registry_url          = "image-registry.openshift-image-registry.svc:5000"
  ibmcloud_release_name = "ibmcloud-config"
  cluster_type_cleaned  = regex("(kubernetes|iks|openshift|ocp3|ocp4).*", var.cluster_type)[0]
  cluster_type          = local.cluster_type_cleaned == "ocp3" ? "openshift" : (local.cluster_type_cleaned == "ocp4" ? "openshift" : (local.cluster_type_cleaned == "iks" ? "kubernetes" : local.cluster_type_cleaned))
  # value should be ocp4, ocp3, or kubernetes
  cluster_type_code     = local.cluster_type_cleaned == "openshift" ? "ocp3" : (local.cluster_type_cleaned == "iks" ? "kubernetes" : local.cluster_type_cleaned)
  cluster_type_tag      = local.cluster_type == "kubernetes" ? "iks" : "ocp"
  ingress_subdomain     = var.ingress_subdomain != "" ? var.ingress_subdomain : data.local_file.ingress_subdomain.content
  ingress_subdomain_file = "${local.tmp_dir}/ingress_subdomain.val"
  console_host_file      = "${local.tmp_dir}/console.host"
  console_url  = "https://${data.local_file.console_host.content}"
  gitops_dir   = var.gitops_dir != "" ? var.gitops_dir : "${path.cwd}/gitops"
  chart_name   = "cloud-setup"
  chart_dir    = "${local.gitops_dir}/${local.chart_name}"
  global_config = {
    clusterType = local.cluster_type_code
    ingressSubdomain = local.ingress_subdomain
  }
  ibmcloud_config = {
    server_url = var.server_url
    cluster_type = local.cluster_type
    ingress_subdomain = local.ingress_subdomain
  }
  github_config = {
    name = "github"
    displayName = "GitHub"
    url = "https://github.com"
    applicationMenu = true
  }
  imageregistry_config = {
    name = "registry"
    displayName = "Image Registry"
    url = "${local.console_url}/k8s/ns/all-projects/imagestreams"
    privateUrl = local.registry_url
    otherSecrets = {
      namespace = var.registry_namespace
    }
    username = var.login_user
    password = var.login_password
    applicationMenu = true
  }
  cntk_dev_guide_config = {
    name = "cntk-dev-guide"
    displayName = "Cloud-Native Toolkit"
    url = "https://cloudnativetoolkit.dev"
  }
  first_app_config = {
    name = "first-app"
    displayName = "Deploy first app"
    url = "https://cloudnativetoolkit.dev/getting-started/deploy-app"
  }
}

resource "null_resource" "create_dirs" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.tmp_dir}"
  }
}

resource "null_resource" "oc_login" {
  count = local.cluster_type == "openshift" ? 1 : 0

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/oc-login.sh \"${var.server_url}\" \"${var.login_user}\" \"${var.login_password}\" \"${var.login_token}\""
  }
}

resource "null_resource" "get_ingress_subdomain" {
  depends_on = [null_resource.oc_login, null_resource.create_dirs]
  count = var.ingress_subdomain == "" ? 1 : 0

  provisioner "local-exec" {
    command = "${path.module}/scripts/get-ingress-subdomain.sh ${local.ingress_subdomain_file}"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }
}

data "local_file" "ingress_subdomain" {
  depends_on = [null_resource.get_ingress_subdomain]

  filename = local.ingress_subdomain_file
}

resource "null_resource" "get_console_host" {
  depends_on = [null_resource.oc_login, null_resource.create_dirs]

  provisioner "local-exec" {
    command = "kubectl get -n openshift-console route/console -o jsonpath='{.spec.host}' > ${local.console_host_file}"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }
}

data "local_file" "console_host" {
  depends_on = [null_resource.get_console_host]

  filename = local.console_host_file
}

resource "null_resource" "setup-chart" {
  depends_on = [null_resource.create_dirs]

  provisioner "local-exec" {
    command = "mkdir -p ${local.chart_dir} && cp -R ${path.module}/chart/${local.chart_name}/* ${local.chart_dir}"
  }
}

resource "null_resource" "delete-helm-cloud-config" {
  depends_on = [null_resource.oc_login]

  provisioner "local-exec" {
    command = "kubectl delete secret -n ${local.config_namespace} -l name=${local.ibmcloud_release_name} || exit 0"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete secret -n ${local.config_namespace} -l name=cloud-setup || exit 0"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete secret -n ${local.config_namespace} github-access || exit 0"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete configmap -n ${local.config_namespace} github-config || exit 0"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete secret -n ${local.config_namespace} registry-access || exit 0"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete configmap -n ${local.config_namespace} registry-config || exit 0"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete secret -n ${local.config_namespace} ibmcloud-apikey || exit 0"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete configmap -n ${local.config_namespace} ibmcloud-config || exit 0"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete secret -n ${local.config_namespace} cloud-access || exit 0"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete configmap -n ${local.config_namespace} cloud-config || exit 0"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete consolelink toolkit-github || exit 0"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete consolelink toolkit-registry || exit 0"

    environment = {
      KUBECONFIG = local.cluster_config
    }
  }
}

resource "local_file" "cloud-values" {
  depends_on = [null_resource.setup-chart]

  content  = yamlencode({
    global = local.global_config
    cloud-setup = {
      ibmcloud = local.ibmcloud_config
      github-config = local.github_config
      imageregistry-config = local.imageregistry_config
      cntk-dev-guide = local.cntk_dev_guide_config
      first-app = local.first_app_config
    }
  })
  filename = "${local.chart_dir}/values.yaml"
}

resource "null_resource" "print-values" {
  provisioner "local-exec" {
    command = "cat ${local_file.cloud-values.filename}"
  }
}

resource "helm_release" "cloud_setup" {
  depends_on = [null_resource.oc_login, null_resource.delete-helm-cloud-config, local_file.cloud-values]

  name              = "cloud-setup"
  chart             = local.chart_dir
  version           = "0.1.0"
  namespace         = local.config_namespace
  timeout           = 1200
  dependency_update = true
  force_update      = true
  replace           = true

  disable_openapi_validation = true
}
