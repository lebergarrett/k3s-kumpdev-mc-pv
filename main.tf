provider "kubernetes" {
  config_path = "~/.kube/config"
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

resource "kubernetes_persistent_volume_claim" "fabric_mods" {
  metadata {
    name      = "fabric-mods"
    namespace = kubernetes_namespace._.metadata.0.name
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "microk8s-hostpath"
    resources {
      requests = {
        storage = each.value
      }
    }
  }
}