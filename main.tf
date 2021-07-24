provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "kubernetes_namespace" "_" {
  metadata {
    name = var.server_name
  }
}

resource "kubernetes_persistent_volume_claim" "_" {
  for_each = var.server_list
  metadata {
    name      = each.key
    namespace = kubernetes_namespace._.metadata.0.name
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "microk8s-hostpath"
    resources {
      requests = {
        storage = each.value
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "luckperms_mariadb" {
  metadata {
    name      = "luckperms-mariadb"
    namespace = kubernetes_namespace._.metadata.0.name
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "microk8s-hostpath"
    resources {
      requests = {
        storage = "500M"
      }
    }
  }
}

resource "null_resource" "backup_cronjob" {
  triggers = {
    backup_paths = join(", ", local.backup_paths)
    server_name  = var.server_name
  }

  provisioner "local-exec" {
    when    = create
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u lab -i 192.168.1.41, ansible/cronjob.yaml --extra-vars '{\"servers\": [${self.triggers.backup_paths}], \"server_namespace\": \"${self.triggers.server_name}\", \"state\": \"present\"}'"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u lab -i 192.168.1.41, ansible/cronjob.yaml --extra-vars '{\"servers\": [${self.triggers.backup_paths}], \"server_namespace\": \"${self.triggers.server_name}\", \"state\": \"absent\"}'"
  }
}

locals {
  backup_paths = concat([
    # MC servers
    for server, volsize in var.server_list : "\"${var.server_name}-${server}-pvc-${kubernetes_persistent_volume_claim._[server].metadata.0.uid}\""
    ], [
    # Luckperms mariadb
    "\"${var.server_name}-${kubernetes_persistent_volume_claim.luckperms_mariadb.metadata.0.name}-pvc-${kubernetes_persistent_volume_claim.luckperms_mariadb.metadata.0.uid}\""
  ])
}