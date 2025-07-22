# Infrastructure

Provision DigitalOcean droplets for containerized microservices.

## Stack

- **Terraform**: Provisions Ubuntu droplets, SSH keys
- **Ansible**: Configures Docker Swarm, Nginx proxy, security
- **Docker Swarm**: Runs IAM + Patient services 
- **Nginx**: SSL proxy at `microservices.khoa.email`

## Structure

- `terraform/`: Infrastructure (`main.tf`, scripts, SSH keys)
- `ansible/`: Server config (`init_playbook.yml`, vars)
- `docker-swarm/`: App deployment (`compose.yml`, scripts)
- `nginx/`: Reverse proxy config
- `scripts/`: Operations tools

## Usage

1. Set `DIGITALOCEAN_TOKEN` in `terraform/.env`
2. Run `terraform/scripts/apply.sh`
3. Run `ansible/scripts/init.sh <ip>`
4. Deploy: `ssh khoa@<ip>` → `cd /opt/microservices` → `./scripts/deploy.sh`
