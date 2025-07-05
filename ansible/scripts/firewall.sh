#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <host_ip>"
    exit 1
fi

HOST_IP=$1

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
    -i "${HOST_IP}," \
    --private-key ~/.ssh/id_ed25519 \
    -u root \
    "$(dirname "$0")"/../firewall_playbook.yml
