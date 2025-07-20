terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
}

resource "digitalocean_ssh_key" "khoadesktop" {
  name       = "Khoa's DigitalOcean SSH key"
  public_key = file("${path.module}/keys/khoadesktop.pub")
}

resource "digitalocean_ssh_key" "khoalaptop" {
  name       = "Khoa's DigitalOcean SSH key"
  public_key = file("${path.module}/keys/khoalaptop.pub")
}

resource "digitalocean_ssh_key" "anh" {
  name       = "Anh's DigitalOcean SSH key"
  public_key = file("${path.module}/keys/anh.pub")
}

resource "digitalocean_droplet" "microservices" {
  count  = 1
  image  = "ubuntu-22-04-x64"
  name   = "microservices-${count.index + 1}"
  region = "sgp1"
  size   = "s-2vcpu-8gb-amd"
  ssh_keys = [
    digitalocean_ssh_key.khoadesktop.id,
    digitalocean_ssh_key.khoalaptop.id,
    digitalocean_ssh_key.anh.id,
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
  value = [for droplet in digitalocean_droplet.microservices : droplet.ipv4_address]
}

