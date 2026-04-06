#!/bin/bash
set -euo pipefail

# Force script to run from the root of capi_soil_moisture directory
cd "$(dirname "$0")/.." || exit 1

# Save default kubeconfig (Management Cluster) before overwriting
MGMT_KUBECONFIG=${KUBECONFIG:-~/.kube/config}

# Load variables (sets KUBECONFIG to workload cluster path)
source ./exp_vars

echo "Deleting app workloads from Workload Cluster..."
kubectl delete -k ./apps/soil_moisture --ignore-not-found=true || true

echo "Deleting CAPI Cluster resources..."
KUBECONFIG="$MGMT_KUBECONFIG" kubectl delete -k ./cluster --ignore-not-found=true || true
KUBECONFIG="$MGMT_KUBECONFIG" kubectl delete cluster pi-cluster --ignore-not-found=true || true

echo "Cleaning up edge daemons on Raspberry Pi worker nodes..."

# Clean up Publisher (pi3)
ssh -o StrictHostKeyChecking=no pi3@$PUBLISHER_IP "sudo systemctl stop mqtt_publisher_service || true; \
    sudo systemctl disable mqtt_publisher_service || true; \
    sudo rm -f /etc/systemd/system/mqtt_publisher_service.service; \
    rm -f /home/pi3/services/mqtt_publisher_service.py; \
    sudo rm -f /etc/default/mqtt_publisher_service; \
    sudo systemctl daemon-reload"

# Clean up Actuator (pi2)
ssh -o StrictHostKeyChecking=no pi2@$ACTUATOR_IP "sudo systemctl stop actuator_service || true; \
    sudo systemctl disable actuator_service || true; \
    sudo rm -f /etc/systemd/system/actuator_service.service; \
    rm -f /home/pi2/services/actuator_service.py; \
    sudo rm -f /etc/default/actuator_service; \
    sudo systemctl daemon-reload"

echo "Cleanup complete."