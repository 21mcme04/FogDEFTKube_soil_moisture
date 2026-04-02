#!/bin/bash

# Load variables
source ../exp_vars

echo "Deploying Cluster API definitions..."
kubectl apply -k ../cluster
kubectl apply -k ../secrets

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

echo "Deployment initiated successfully!"


kubectl apply -k ../apps/soil_moisture