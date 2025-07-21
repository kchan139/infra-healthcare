#!/bin/bash
set -e

PROJECT_ROOT="$(dirname "$0")/../.."
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"
INVENTORY_FILE="$ANSIBLE_DIR/inventory.ini"
SSH_PORT=1309

# Generate inventory.ini
echo "[servers]" > "$INVENTORY_FILE"
terraform -chdir="$TERRAFORM_DIR" output -json droplet_ips \
  | jq -r '.[] | . + " ansible_port=1309"' \
  >> "$INVENTORY_FILE"

echo "Generated inventory:"
cat "$INVENTORY_FILE"
echo

# Run Ansible playbook using the generated inventory
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
    -i "$INVENTORY_FILE" \
    --private-key ~/.ssh/id_ed25519 \
    -u khoa \
    -e ssh_port=$SSH_PORT \
    "$ANSIBLE_DIR/init_playbook.yml" \
    --ask-vault-pass \
    --ask-become-pass
