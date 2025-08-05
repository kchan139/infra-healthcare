# === Cloudflare DNS Record ===

resource "cloudflare_dns_record" "microservices_subdomain" {
  zone_id = var.cloudflare_zone_id
  // --- SUB DOMAIN NAME --- //
  name    = var.subdomain_name
  type    = "A"
  content = digitalocean_loadbalancer.nodes.ip
  ttl     = 1
  proxied = true
}
