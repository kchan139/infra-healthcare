# === DigitalOcean's Load Balancer ===

# --- Load Balancer Certificate ---
resource "digitalocean_certificate" "cert" {
  name             = "origin-cert"
  private_key      = file("${path.module}/secrets/origin.key")
  leaf_certificate = file("${path.module}/secrets/origin.crt")
}

# --- Load Balancer Configuration ---
resource "digitalocean_loadbalancer" "nodes" {
  name   = "nodes-load-balancer"
  region = "sgp1"

  vpc_uuid = digitalocean_vpc.private.id

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

  firewall {
    allow = var.cloudflare_ipv4
  }

  droplet_ids = concat(
    [digitalocean_droplet.manager.id],
    digitalocean_droplet.workers[*].id
  )
}
