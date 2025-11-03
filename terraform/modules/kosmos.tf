resource "scaleway_k8s_cluster" "kosmos_cluster" {
  name                        = "kosmos-cluster"
  type                        = "multicloud"
  version                     = "1.32.3"
  cni                         = "kilo"
  project_id                  = var.scw_project_id
  delete_additional_resources = false
  tags                        = ["terraform"]
}

resource "scaleway_k8s_pool" "internal_pool" {
  cluster_id  = scaleway_k8s_cluster.kosmos_cluster.id
  name        = "internal-node"
  node_type   = "DEV1-M" #Instances with insufficient memory are not eligible (DEV1-S, PLAY2-PICO, STARDUST)
  size        = 1
  min_size    = 1
  max_size    = 2
  autoscaling = true
  autohealing = true
  tags        = ["terraform"]
}

resource "scaleway_k8s_pool" "external_pool" {
  cluster_id = scaleway_k8s_cluster.kosmos_cluster.id
  name       = "external-node"
  node_type  = "external"
  size       = 2
  min_size   = 0
  tags       = ["terraform"]
}