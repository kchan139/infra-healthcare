terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# resource "digitalocean_ssh_key" "khoa" {
#   name       = "Khoa's DigitalOcean SSH key"
#   public_key = var.khoa_ssh_public_key
# }

resource "digitalocean_ssh_key" "anh" {
  name       = "Tieu Anh's DigitalOcean SSH key"
  public_key = var.anh_ssh_public_key
}

data "digitalocean_ssh_key" "khoa" {
  name = "Khoa SSH key"
}

# data "digitalocean_ssh_key" "anh" {
#   name = "Tieu Anh's DigitalOcean SSH key"
# }

resource "cloudflare_dns_record" "microservices_subdomain" {
  zone_id = var.cloudflare_zone_id
  // --- SUB DOMAIN NAME --- //
  name    = "api"
  type    = "A"
  content = digitalocean_loadbalancer.nodes.ip
  ttl     = 1
  proxied = true
}

resource "digitalocean_loadbalancer" "nodes" {
  name   = "nodes-load-balancer"
  region = "sgp1"

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 80
    target_protocol = "http"
  }

  healthcheck {
    protocol = "http"
    port     = 80
    path     = "/"
  }

  droplet_ids = digitalocean_droplet.nodes.*.id
}

resource "digitalocean_droplet" "nodes" {
  count  = 1
  image  = "ubuntu-24-04-x64"
  name   = "nodes-${count.index + 1}"
  region = "sgp1"
  size   = "s-4vcpu-8gb-intel"
  ssh_keys = [
    # digitalocean_ssh_key.khoa.id,
    digitalocean_ssh_key.anh.id,
    data.digitalocean_ssh_key.khoa.id,
    # data.digitalocean_ssh_key.anh.id,
  ]

  # provisioner "local-exec" {
  #   command = "sleep 30 && ../ansible/scripts/init.sh ${self.ipv4_address}"
  #   when    = create
  # }

  backups = false
  # backups = true
  # backup_policy {
  #   plan    = "weekly"
  #   weekday = "TUE"
  #   hour    = 8
  # }
}

output "droplet_ips" {
  value = [for droplet in digitalocean_droplet.nodes : droplet.ipv4_address]
}

output "load_balancer_ip" {
  value = digitalocean_loadbalancer.nodes.ip
}
