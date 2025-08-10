# Healthcare Microservices Infrastructure

Containerized microservices platform deployed on DigitalOcean with SSL termination, Cloudflare protection, and load balancing.

---

**🌐 Live at: [https://fhard.khoa.email](https://fhard.khoa.email)**

## Stack

* **Terraform**: Provisions Ubuntu droplets in private VPC, SSH keys, load balancer, firewall rules, SSL certs, and DNS records
* **Ansible**: Sets up Docker Swarm, applies security hardening, and manages users and Docker secrets
* **Cloudflare**: DNS management with CDN proxy and IPv4 CIDR blocks whitelisted at the load balancer
* **DigitalOcean Load Balancer**: SSL termination, firewall-based filtering, and service routing
* **Nginx**: Reverse proxy with path-based routing
* **Docker Swarm**: IAM + Patient + Test Order services with health checks

## Architecture

**Full System:**

* **Frontend**: Deployed on Netlify (handled by FE team)
* **Backend**: *This infrastructure* (IAM + Patient + Test Order services)
* **Databases**: DigitalOcean Managed PostgreSQL, MongoDB Atlas
* **Message Broker**: RabbitMQ via CloudAMQP

**Infrastructure Nodes:**
- 1 Manager Node - 4vCPU/8GB
- 1 Worker Node - 2vCPU/4GB (tight budget)
- Private VPC (10.100.0.0/24)

**Traffic Flow:**

```
      Frontend
          ↓
     Cloudflare
          ↓
    Load Balancer
          ↓
        Nginx
          ↓
    Services APIs
          ↓
Databases, Message Broker
```

---

## Project Structure

```
├── terraform/          # Infrastructure as Code
├── ansible/            # Server configuration & secrets
├── swarm/              # Docker Compose stack
└── swarm/nginx/        # Reverse proxy config
```

## Deployment

### Prerequisites

* DigitalOcean and Cloudflare API tokens set in `terraform/terraform.tfvars` (see `variables.tf` for required vars)
* Ansible vault (`ansible/vars/password.yml`) for secrets
* SSH keys configured

### Steps

1. **Provision infrastructure**: `cd terraform && terraform init && terraform apply`
2. **Configure servers**: `cd ansible && ./scripts/init.sh`
3. **Deploy services**: SSH to server → `cd /opt/microservices` → `./scripts/deploy.sh`

### Swarm Management

* `./scripts/deploy.sh` - Deploy/update stack
* `./scripts/remove.sh` - Remove stack
* `./scripts/cleanup.sh` - Remove all stacks
* `./scripts/logs.sh <service>` - View logs (iam/patient/testorder)

## Security & Reliability

**Security:**

* Load balancer handles SSL termination and traffic filtering
* Load balancer firewall only allows Cloudflare IPv4 ranges
* DigitalOcean firewall: allows SSH from trusted IPs, HTTP only from the load balancer
* Custom SSH port with key-based authentication only
* UFW firewall with additional port restrictions
* VPC-private node communication
* Nginx blocks sensitive endpoints
* Docker secrets for credentials
* No source code on server (container images only)

**High Availability (sort of):**

* 3 replicas per service with health checks
* Rolling updates with automatic rollback
* Resource limits and reservations
* Load balancer health monitoring

**Limitations:**
* Centralized logging not implemented due to time constraints
* Single worker node due to budget constraints
* Manual failover required for manager node
* Basic health checks without detailed metrics
