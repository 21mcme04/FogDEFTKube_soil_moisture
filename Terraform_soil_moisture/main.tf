module "infrastructure" {
  source       = "./modules/infrastructure"
  master_node  = var.master_node
  worker_nodes = var.worker_nodes
}

module "soil_moisture_k3s" {
  source          = "./modules/k3s_workloads"
  manifest_url    = var.k3s_manifest_url
  kubeconfig_path = "${path.root}/kubeconfig.yaml"
  
  depends_on = [module.infrastructure]
}

module "publisher_daemon" {
  source       = "./modules/system_daemon"
  node_ip      = var.worker_nodes["publisher_node"].ip
  node_user    = var.worker_nodes["publisher_node"].user
  service_name = "mqtt_publisher_service"
  script_url   = "https://gist.githubusercontent.com/21mcme04/acdea1dfc4483d79a3510945ef201e64/raw/9b3c0015d971d4018bfb72fb2e742fe04526531c/publisher-soil-moisture.py"
  service_url  = "https://gist.githubusercontent.com/21mcme04/cd1e732ee5185c5a52b278439d32cd70/raw/e8d0e3b4eb06b46129bfdbd95270a95f6cc75a8e/publisher-soil-service.service"
  broker_url   = "${var.master_node.ip}:31883"

  depends_on = [module.soil_moisture_k3s]
}

module "actuator_daemon" {
  source       = "./modules/system_daemon"
  node_ip      = var.worker_nodes["actuator_node"].ip
  node_user    = var.worker_nodes["actuator_node"].user
  service_name = "actuator_service"
  script_url   = "https://gist.githubusercontent.com/21mcme04/ffcfc4f88ca37fc0ab03c4cc2a1ef254/raw/8322fb0710b0e9f7ff0940631fc08a0ab65d3ea5/actuator-soil-servo.py"
  service_url  = "https://gist.githubusercontent.com/21mcme04/3384f13aff3fc51a3badced81150102a/raw/f976fa409b0495f6a490e8f7739d0f31a05229fb/actuator-soil-service.service"
  broker_url   = "${var.master_node.ip}:31883"

  depends_on = [module.soil_moisture_k3s]
}