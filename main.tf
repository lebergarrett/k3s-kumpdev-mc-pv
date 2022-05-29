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
    name = var.namespace
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
    storage_class_name = "local-path"
    resources {
      requests = {
        storage = each.value
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "luckperms_mariadb" {
  count = var.luckperms_enabled == true ? 1 : 0
  metadata {
    name      = "luckperms-mariadb"
    namespace = kubernetes_namespace._.metadata.0.name
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "local-path"
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
    namespace    = var.namespace
  }

  provisioner "local-exec" {
    when    = create
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u lab -i 192.168.0.81, ansible/cronjob.yaml --extra-vars '{\"servers\": [${self.triggers.backup_paths}], \"server_namespace\": \"${self.triggers.namespace}\", \"state\": \"present\"}'"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u lab -i 192.168.0.81, ansible/cronjob.yaml --extra-vars '{\"servers\": [${self.triggers.backup_paths}], \"server_namespace\": \"${self.triggers.namespace}\", \"state\": \"absent\"}'"
  }
}

locals {
  backup_paths = concat([
    # MC servers
    for server, volsize in var.server_list : "\"pvc-${kubernetes_persistent_volume_claim._[server].metadata.0.uid}_${var.namespace}_${server}\""
    ], var.luckperms_enabled == true ? [
    # Luckperms mariadb
    "\"pvc-${kubernetes_persistent_volume_claim.luckperms_mariadb[0].metadata.0.uid}_${var.namespace}_${kubernetes_persistent_volume_claim.luckperms_mariadb[0].metadata.0.name}\""
  ] : [])
}
