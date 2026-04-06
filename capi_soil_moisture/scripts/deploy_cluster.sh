#!/bin/bash
set -euo pipefail

# Force script to run from the root of capi_soil_moisture directory
cd "$(dirname "$0")/.." || exit 1

# Save default kubeconfig (Management Cluster) before overwriting
MGMT_KUBECONFIG=${KUBECONFIG:-~/.kube/config}

# Load variables (sets KUBECONFIG to workload cluster path)
source ./exp_vars

echo "Restarting k0smotron controller to refresh CNI routing..."
KUBECONFIG="$MGMT_KUBECONFIG" kubectl delete pod -n k0smotron -l control-plane=controller-manager --ignore-not-found=true || true
KUBECONFIG="$MGMT_KUBECONFIG" kubectl wait --for=condition=Ready pod -n k0smotron -l control-plane=controller-manager --timeout=180s

echo "Deploying Cluster API definitions to Management Cluster..."
KUBECONFIG="$MGMT_KUBECONFIG" kubectl apply -k ./secrets
KUBECONFIG="$MGMT_KUBECONFIG" kubectl apply -k ./cluster

echo "Injecting Publisher Daemon on Pi 3 ($PUBLISHER_IP)..."
ssh -o StrictHostKeyChecking=no pi3@$PUBLISHER_IP << 'EOF'
  sudo apt-get update && sudo apt-get install -y python3-pip wget
  sudo pip3 install paho-mqtt RPi.GPIO --break-system-packages || sudo pip3 install paho-mqtt RPi.GPIO
  mkdir -p /home/pi3/services
  wget -O /home/pi3/services/mqtt_publisher_service.py https://gist.githubusercontent.com/21mcme04/acdea1dfc4483d79a3510945ef201e64/raw/publisher-soil-moisture.py
  sed -i "s/localhost/192.168.0.204/g" /home/pi3/services/mqtt_publisher_service.py
  sed -i "s/1883/31883/g" /home/pi3/services/mqtt_publisher_service.py

  sudo bash -c 'cat <<SERVICE > /etc/systemd/system/mqtt_publisher_service.service
[Unit]
Description=mqtt_publisher_service
After=network.target

[Service]
Type=simple
User=pi3
WorkingDirectory=/home/pi3/services
ExecStart=/usr/bin/python3 /home/pi3/services/mqtt_publisher_service.py
EnvironmentFile=-/etc/default/mqtt_publisher_service
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE'

  sudo bash -c 'echo "MQTT_BROKER=192.168.0.204" > /etc/default/mqtt_publisher_service'
  sudo bash -c 'echo "MQTT_PORT=31883" >> /etc/default/mqtt_publisher_service'

  sudo systemctl daemon-reload
  sudo systemctl enable mqtt_publisher_service
  sudo systemctl restart mqtt_publisher_service
EOF

echo "Injecting Actuator Daemon on Pi 2 ($ACTUATOR_IP)..."
ssh -o StrictHostKeyChecking=no pi2@$ACTUATOR_IP << 'EOF'
  sudo apt-get update && sudo apt-get install -y python3-pip wget
  sudo pip3 install paho-mqtt RPi.GPIO --break-system-packages || sudo pip3 install paho-mqtt RPi.GPIO
  mkdir -p /home/pi2/services
  wget -O /home/pi2/services/actuator_service.py https://gist.githubusercontent.com/21mcme04/ffcfc4f88ca37fc0ab03c4cc2a1ef254/raw/actuator-soil-servo.py
  sed -i "s/localhost/192.168.0.204/g" /home/pi2/services/actuator_service.py
  sed -i "s/1883/31883/g" /home/pi2/services/actuator_service.py

  sudo bash -c 'cat <<SERVICE > /etc/systemd/system/actuator_service.service
[Unit]
Description=actuator_service
After=network.target

[Service]
Type=simple
User=pi2
WorkingDirectory=/home/pi2/services
ExecStart=/usr/bin/python3 /home/pi2/services/actuator_service.py
EnvironmentFile=-/etc/default/actuator_service
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE'

  sudo bash -c 'echo "MQTT_BROKER=192.168.0.204" > /etc/default/actuator_service'
  sudo bash -c 'echo "MQTT_PORT=31883" >> /etc/default/actuator_service'

  sudo systemctl daemon-reload
  sudo systemctl enable actuator_service
  sudo systemctl restart actuator_service
EOF

echo "Waiting for Working Cluster to be provisioned (this may take up to 10 minutes)..."
until KUBECONFIG="$MGMT_KUBECONFIG" kubectl get secret pi-cluster-kubeconfig -n default >/dev/null 2>&1; do
  echo "Still initializing control plane..."
  sleep 15
done

echo "Extracting workload kubeconfig..."
KUBECONFIG="$MGMT_KUBECONFIG" clusterctl get kubeconfig pi-cluster > ./pi-cluster-kubeconfig.yaml
export KUBECONFIG="$PWD/pi-cluster-kubeconfig.yaml"

echo "Ensuring local-path storage provisioner in workload cluster..."
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' || true

echo "Deploying soil moisture workloads to workload cluster..."
kubectl apply -k ./apps/soil_moisture

echo "Deployment initiated successfully!"