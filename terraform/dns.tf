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

resource "cloudflare_dns_record" "mt86_verification" {
  zone_id = var.cloudflare_zone_id
  name    = "mt86"
  type    = "CNAME"
  content = "smtp.mailtrap.live"
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "dkim_1" {
  zone_id = var.cloudflare_zone_id
  name    = "rwmt1._domainkey"
  type    = "CNAME"
  content = "rwmt1.dkim.smtp.mailtrap.live"
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "dkim_2" {
  zone_id = var.cloudflare_zone_id
  name    = "rwmt2._domainkey"
  type    = "CNAME"
  content = "rwmt2.dkim.smtp.mailtrap.live"
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "dmarc" {
  zone_id = var.cloudflare_zone_id
  name    = "_dmarc"
  type    = "TXT"
  content = "\"v=DMARC1; p=none; rua=mailto:dmarc@smtp.mailtrap.live; ruf=mailto:dmarc@smtp.mailtrap.live; rf=afrf; pct=100\""
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "mt_link_tracking" {
  zone_id = var.cloudflare_zone_id
  name    = "mt-link"
  type    = "CNAME"
  content = "t.mailtrap.live"
  ttl     = 1
  proxied = false
}
