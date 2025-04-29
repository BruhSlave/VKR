#!/bin/bash
set -e

SHARED_DIR="/var/lib/jenkins/shared-terraform"
ANSIBLE_DIR="/var/lib/jenkins/ansible"

echo "Generating Ansible inventory from Terraform outputs..."

cd "$SHARED_DIR"

# Create inventory file with nodes group
{
  echo "[nodes]"
  jq -r '.nat_vm_external_ips.value | to_entries[] | "\(.value) ansible_user=ubuntu"' terraform-outputs.json
} > "${ANSIBLE_DIR}/inventory"

echo "Ansible inventory successfully created at ${ANSIBLE_DIR}/inventory"
