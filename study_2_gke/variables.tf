variable "project" {
  default = "pj-ibp"
}

variable "cluster_name" {
  default = "cluster"
}

variable "location" {
  default = "asia-northeast1-a"
}

variable "network" {
  default = "default"
}

variable "primary_node_count" {
  default = "3"
}

variable "machine_type" {
  default = "n1-standard-1"
}

variable "min_master_version" {
  default = "1.12.6-gke.7"
}

variable "node_version" {
  default = "1.12.6-gke.7"
}