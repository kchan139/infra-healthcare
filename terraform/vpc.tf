# === Virtual Private Cloud ===

resource "digitalocean_vpc" "private" {
  name     = "microservices-vpc"
  region   = "sgp1"
  ip_range = "10.100.0.0/24"
}
