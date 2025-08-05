# === Droplet Nodes ===

# --- Manager Node ---
resource "digitalocean_droplet" "manager" {
  name   = "manager-node"
  image  = "ubuntu-24-04-x64"
  region = "sgp1"
  size   = "s-4vcpu-8gb"

  vpc_uuid = digitalocean_vpc.private.id

  ssh_keys = [
    data.digitalocean_ssh_key.khoa.id,
    digitalocean_ssh_key.anh.id,
    digitalocean_ssh_key.phong.id,
  ]

  backups = false
  # backups = true
  # backup_policy {
  #   plan    = "weekly"
  #   weekday = "TUE"
  #   hour    = 8
  # }
}

# --- Worker Nodes ---
resource "digitalocean_droplet" "workers" {
  count  = 1
  name   = "worker-node-${count.index + 1}"
  image  = "ubuntu-24-04-x64"
  region = "sgp1"
  size   = "s-2vcpu-4gb"

  vpc_uuid = digitalocean_vpc.private.id

  ssh_keys = [
    data.digitalocean_ssh_key.khoa.id,
    digitalocean_ssh_key.anh.id,
    digitalocean_ssh_key.phong.id,
  ]

  backups = false
}
