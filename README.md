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

The servers are configured once during provisioning to be ready for pulling Docker images from registry and running services via Docker Compose.

## Team Access

SSH keys in `terraform/keys/` provide access for: khoadesktop, khoalaptop, anh

## Usage

Set `DIGITALOCEAN_TOKEN` in `terraform/.env`, then use `terraform/scripts/apply.sh` to provision or `destroy.sh` to tear down.
