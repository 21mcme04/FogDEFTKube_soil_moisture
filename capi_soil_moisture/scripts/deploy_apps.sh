#!/bin/bash
set -euo pipefail

# Force script to run from the root of capi_soil_moisture directory
cd "$(dirname "$0")/.." || exit 1

# Load workload kubeconfig and shared vars
source ./exp_vars

kubectl apply -k ./apps/soil_moisture
