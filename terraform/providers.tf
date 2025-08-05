# === Providers ===
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

# --- DigitalOcean ---
provider "digitalocean" {
  token = var.do_token
}

# --- Cloudflare ---
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
