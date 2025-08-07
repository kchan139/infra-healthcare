# === Cloudflare DNS Records ===

resource "cloudflare_dns_record" "microservices_subdomain" {
  zone_id = var.cloudflare_zone_id
  // --- SUB DOMAIN NAME --- //
  name    = var.subdomain_name
  type    = "A"
  content = digitalocean_loadbalancer.nodes.ip
  ttl     = 1
  proxied = true
}

# MX Record
resource "cloudflare_dns_record" "send_mx" {
  zone_id  = var.cloudflare_zone_id
  name     = "send"
  type     = "MX"
  content  = "feedback-smtp.ap-northeast-1.amazonses.com"
  priority = 10
  ttl      = 1
  proxied  = false
}

# SPF Record (TXT)
resource "cloudflare_dns_record" "send_spf" {
  zone_id = var.cloudflare_zone_id
  name    = "send"
  type    = "TXT"
  content = "\"v=spf1 include:amazonses.com ~all\""
  ttl     = 1
  proxied = false
}

# DKIM Record (TXT)
resource "cloudflare_dns_record" "resend_dkim" {
  zone_id = var.cloudflare_zone_id
  name    = "resend._domainkey"
  type    = "TXT"
  content = "\"p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCjg1dpEdhjeckK7V+o38zrQJ8cjOMEN91wrgbGqyZ2R8E6l+luBvtDAhQxp8oibAbvFtnw09cUUq7NAmhgUfvYm6gGV8l3jqYT51DaD5bkGYasevseVoxGsxK7+qTmNFrqcQVM86W/7huCTfBop307JG4qeXTZWkYcx9vKWu4UyQIDAQAB\""
  ttl     = 1
  proxied = false
}

