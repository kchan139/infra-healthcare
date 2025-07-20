# Infrastructure

**DevOps Team Only**

Provision and configure DigitalOcean droplets for containerized microservices.

## Overview

- **Terraform**: Provisions Ubuntu droplets (2 vCPU, 8GB RAM), manages SSH keys, and outputs inventory.
- **Ansible**: Bootstraps Docker hosts with secure user access, UFW firewall, SSH hardening, and Nginx reverse proxy.
- **Nginx**: Serves as SSL-terminated reverse proxy for microservices at `droplet.khoa.email`.
- **Scripts**: Automate provisioning, security auditing, Docker ops, and system monitoring.

## Structure

- `terraform/`: Infrastructure provisioning (`main.tf`, `apply.sh`, `destroy.sh`)
- `ansible/`: Playbooks (`init_playbook.yml`), helper scripts, vault-secured vars
- `nginx/`: Reverse proxy config with static root and API routing
- `scripts/`: Server management, Cloudflare's IP whitelisting, log analysis, WHOIS, backups

## Usage

1. Set `DIGITALOCEAN_TOKEN` in `terraform/.env`
2. Run `terraform/scripts/apply.sh` to provision
3. Use `ansible/scripts/init.sh` to config
4. Manage servers via `scripts/server-mgmt`

SSH access managed via `terraform/keys/`
