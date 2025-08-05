#!/bin/bash
set -e

PROJECT_ROOT="$(dirname "$0")/../.."
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"
INVENTORY_FILE="$ANSIBLE_DIR/inventory.ini"

source "$ANSIBLE_DIR/.env"

# Get IPs from Terraform outputs
MANAGER_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw manager_ip)
WORKER_IPS=$(terraform -chdir="$TERRAFORM_DIR" output -json worker_ips | jq -r '.[]')

# === Create inventory using updated user and SSH port ===
echo "[manager]" > "$INVENTORY_FILE"
echo "manager-node ansible_host=$MANAGER_IP ansible_port=$SSH_PORT" >> "$INVENTORY_FILE"
echo "" >> "$INVENTORY_FILE"
echo "[workers]" >> "$INVENTORY_FILE"
i=1
for ip in $WORKER_IPS; do
  echo "worker-node-$i ansible_host=$ip ansible_port=$SSH_PORT" >> "$INVENTORY_FILE"
  i=$((i+1))
done

echo "[*] Inventory for re-run (user: $USER_NAME, port: $SSH_PORT):"
cat "$INVENTORY_FILE"
echo

# === Re-run setup.yml and playbook.yml using updated user and port ===

# ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
#     -i "$INVENTORY_FILE" \
#     --private-key ~/.ssh/id_ed25519 \
#     -u "$USER_NAME" \
#     "$ANSIBLE_DIR/setup.yml" \
#     --ask-vault-pass \
#     --ask-become-pass \
#     -e ssh_port=$SSH_PORT

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
    -i "$INVENTORY_FILE" \
    --private-key ~/.ssh/id_ed25519 \
    -u "$USER_NAME" \
    "$ANSIBLE_DIR/playbook.yml" \
    --ask-vault-pass \
    --ask-become-pass \
    -e ssh_port=$SSH_PORT
