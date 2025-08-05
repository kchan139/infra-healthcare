# === SHARED RESOURCES ===

# --- SSH Keys ---
# resource "digitalocean_ssh_key" "khoa" {
#   name       = "Khoa's DigitalOcean SSH key"
#   public_key = var.khoa_ssh_public_key
# }

resource "digitalocean_ssh_key" "anh" {
  name       = "Tieu Anh's DigitalOcean SSH key"
  public_key = var.anh_ssh_public_key
}

resource "digitalocean_ssh_key" "phong" {
  name       = "Phong's DigitalOcean SSH key"
  public_key = var.phong_ssh_public_key
}

data "digitalocean_ssh_key" "khoa" {
  name = "Khoa SSH key"
}

# data "digitalocean_ssh_key" "anh" {
#   name = "Tieu Anh's DigitalOcean SSH key"
# }
