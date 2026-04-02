resource "terraform_data" "setup_daemon" {
  # Store variables here so they can be referenced inside the destroy provisioner
  input = {
    host         = var.node_ip
    user         = var.node_user
    service_name = var.service_name
  }

  triggers_replace = [var.script_url, var.service_url]

  # Provisioner for Create/Update
  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = var.node_user
      host = var.node_ip
    }

    inline = [
      "sudo apt-get update && sudo apt-get install -y python3-pip",
      # Install required libraries
      "sudo pip3 install paho-mqtt RPi.GPIO --break-system-packages || sudo pip3 install paho-mqtt RPi.GPIO",
      
      "mkdir -p /home/${var.node_user}/services",
      "wget -O /home/${var.node_user}/services/${var.service_name}.py ${var.script_url}",
      "sudo wget -O /etc/systemd/system/${var.service_name}.service ${var.service_url}",
      
      "sudo sed -i 's/MY_DYNAMIC_USER/${var.node_user}/g' /etc/systemd/system/${var.service_name}.service",

      # Create the Environment File with the EXACT variable names the Python script expects
      "echo 'MQTT_BROKER=${split(":", var.broker_url)[0]}' | sudo tee /etc/default/${var.service_name}",
      "echo 'MQTT_PORT=${split(":", var.broker_url)[1]}' | sudo tee -a /etc/default/${var.service_name}",
      
      # Tell systemd to actually load those variables by injecting EnvironmentFile right above ExecStart
      "sudo sed -i '/^ExecStart=/i EnvironmentFile=/etc/default/${var.service_name}' /etc/systemd/system/${var.service_name}.service",
      
      "sudo systemctl daemon-reload",
      "sudo systemctl enable ${var.service_name}",
      "sudo systemctl restart ${var.service_name}"
    ]
  }

  # Provisioner for Destroy
  provisioner "remote-exec" {
    when = destroy

    # Use self.input.* here to satisfy Terraform's destroy scope requirements
    connection {
      type = "ssh"
      user = self.input.user
      host = self.input.host
    }

    inline = [
      "sudo systemctl stop ${self.input.service_name} || true",
      "sudo systemctl disable ${self.input.service_name} || true",
      "sudo rm -f /etc/systemd/system/${self.input.service_name}.service",
      "rm -f /home/${self.input.user}/services/${self.input.service_name}.py",
      "sudo rm -f /etc/default/${self.input.service_name}",
      "sudo systemctl daemon-reload"
    ]
  }
}