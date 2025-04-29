#!/bin/bash
set -e

SHARED_DIR="/var/lib/jenkins/shared-terraform"
OUTPUT_FILE="/opt/prometheus/file_sd/instances.json"

echo "Generating Prometheus instances.json from Terraform outputs..."

cd "$SHARED_DIR"

IPS=$(jq -r '.nat_vm_external_ips.value[]' terraform-outputs.json)

echo "[" > "$OUTPUT_FILE"

for ip in $IPS; do
  echo "{\"targets\": [\"${ip}:9100\"], \"labels\": {\"job\": \"node_exporter\"}}," >> "$OUTPUT_FILE"
done

# Remove last comma
sed -i '$ s/,$//' "$OUTPUT_FILE"

echo "]" >> "$OUTPUT_FILE"

echo "instances.json generated successfully at $OUTPUT_FILE"

