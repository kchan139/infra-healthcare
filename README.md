# Infrastructure

**DevOps Team Only**

Automated provisioning and configuration for DigitalOcean droplets to host containerized microservices.

## What This Does

This repository uses Terraform to provision Ubuntu 22.04 droplets on DigitalOcean (Singapore region) and Ansible to configure them as Docker hosts ready for microservice deployment.

**Terraform** provisions:
- DigitalOcean droplets (2 vCPU, 8GB RAM)
- SSH key management for team access
- Automatic Ansible configuration on creation

**Ansible** configures:
- Docker and Docker Compose installation
- Development tools (htop, tree, bat, neofetch)
- Starship shell prompt
- User permissions and SSH access
- SSH hardening and UFW firewall setup

**Nginx** provides:
- SSL-terminated reverse proxy (droplet.khoa.email)
- API routing with path rewriting for microservices
- Service endpoints: `/api/iam/`, `/api/patient/`, `/api/testorder/`

**Scripts** include:
- Comprehensive server management tool (`server-mgmt`)
- Health monitoring, resource checks, and Docker management
- Automated backup and maintenance functions

The servers are configured once during provisioning to be ready for pulling Docker images from registry and running services via Docker Compose.

## Components

### Terraform
- **Location**: `terraform/`
- **Main config**: `main.tf`
- **SSH keys**: `terraform/keys/` (khoadesktop, khoalaptop, anh)
- **Scripts**: `apply.sh`, `destroy.sh`

### Ansible
- **Location**: `ansible/`
- **Playbooks**: `init_playbook.yml`, `config_ssh_playbook.yml`, `firewall_playbook.yml`
- **Helper scripts**: `init.sh`, `sshconfig.sh`, `firewall.sh`

### Nginx
- **Location**: `nginx/`
- **Config**: `reverse_proxy.conf`
- **Features**: SSL termination, API path rewriting, microservice routing

### Scripts
- **Location**: `scripts/`
- **Main tool**: `server-mgmt` - comprehensive server management script
- **Features**: health checks, Docker management, system monitoring, automated maintenance

## Team Access

SSH keys in `terraform/keys/` provide access for: khoadesktop, khoalaptop, anh

## Usage

1. Set `DIGITALOCEAN_TOKEN` in `terraform/.env`
2. Use `terraform/scripts/apply.sh` to provision or `destroy.sh` to tear down
3. Use `scripts/server-mgmt` for ongoing server management and monitoring
