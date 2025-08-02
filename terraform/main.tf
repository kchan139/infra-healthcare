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

# --- SSH Keys ---
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

# --- Droplets ---
resource "digitalocean_droplet" "nodes" {
  count  = 1
  image  = "ubuntu-24-04-x64"
  name   = "node-${count.index + 1}"
  region = "sgp1"
  size   = "s-4vcpu-8gb-intel"
  ssh_keys = [
    # digitalocean_ssh_key.khoa.id,
    digitalocean_ssh_key.anh.id,
    data.digitalocean_ssh_key.khoa.id,
    # data.digitalocean_ssh_key.anh.id,
  ]

  backups = false
  # backups = true
  # backup_policy {
  #   plan    = "weekly"
  #   weekday = "TUE"
  #   hour    = 8
  # }
}

# --- Load Balancer Certificate ---
resource "digitalocean_certificate" "cert" {
  name             = "origin-cert"
  private_key      = file("${path.module}/secrets/origin.key")
  leaf_certificate = file("${path.module}/secrets/origin.crt")
}

# --- Load Balancer ---
resource "digitalocean_loadbalancer" "nodes" {
  name   = "nodes-load-balancer"
  region = "sgp1"

  redirect_http_to_https = true

  forwarding_rule {
    entry_port     = 443
    entry_protocol = "https"

    target_port     = 80
    target_protocol = "http"

    certificate_name = digitalocean_certificate.cert.name
    tls_passthrough  = false
  }

  healthcheck {
    protocol = "http"
    port     = 80
    path     = "/"
  }

  droplet_ids = digitalocean_droplet.nodes.*.id
}

# --- Firewall ---
resource "digitalocean_firewall" "nodes" {
  name = "only-ssh-http-and-https"

  droplet_ids = digitalocean_droplet.nodes.*.id

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "1309"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol                  = "tcp"
    port_range                = "80"
    source_load_balancer_uids = [digitalocean_loadbalancer.nodes.id]
  }

  # inbound_rule {
  #   protocol         = "tcp"
  #   port_range       = "443"
  #   source_addresses = ["0.0.0.0/0", "::/0"]
  # }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# --- DNS ---
resource "cloudflare_dns_record" "microservices_subdomain" {
  zone_id = var.cloudflare_zone_id
  // --- SUB DOMAIN NAME --- //
  name    = "fhard"
  type    = "A"
  content = digitalocean_loadbalancer.nodes.ip
  ttl     = 1
  proxied = true
}

# --- Outputs ---
output "droplet_ips" {
  value = [for droplet in digitalocean_droplet.nodes : droplet.ipv4_address]
}

output "load_balancer_ip" {
  value = digitalocean_loadbalancer.nodes.ip
}
