variable "master_node" {
  type = object({ ip = string, user = string })
  default = { ip = "192.168.0.204", user = "pi1" }
}

variable "worker_nodes" {
  type = map(object({ ip = string, user = string }))
  default = {
    "publisher_node" = { ip = "192.168.0.76",  user = "pi3" }
    "actuator_node"  = { ip = "192.168.0.237", user = "pi2" }
  }
}

variable "k3s_manifest_url" {
  type    = string
  default = "https://gist.githubusercontent.com/21mcme04/68c7edc0b0c5653ecd2e138683f3d568/raw/37568afee75c263d8dc7db12fd2aab80fd8598b5/k3s-fogdeft-soil_moisture-manifest.yaml"
}