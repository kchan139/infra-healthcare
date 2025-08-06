resource "digitalocean_firewall" "nodes" {
  name = "droplets-firewall"

  droplet_ids = concat(
    [digitalocean_droplet.manager.id],
    digitalocean_droplet.workers[*].id
  )

  ### SSH Access ###
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.ssh_access_ips
    # source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = var.custom_ssh_port
    source_addresses = var.ssh_access_ips
    # source_addresses = ["0.0.0.0/0", "::/0"]
  }

  ### HTTP from Load Balancer ###
  inbound_rule {
    protocol                  = "tcp"
    port_range                = "80"
    source_load_balancer_uids = [digitalocean_loadbalancer.nodes.id]
  }

  ### Docker Swarm (only from internal node IPs) ###
  # Manager Port for Swarm join
  inbound_rule {
    protocol         = "tcp"
    port_range       = "2377"
    source_addresses = ["10.0.0.0/8"]
  }

  # Node discovery
  inbound_rule {
    protocol         = "tcp"
    port_range       = "7946"
    source_addresses = ["10.0.0.0/8"]
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "7946"
    source_addresses = ["10.0.0.0/8"]
  }

  # Overlay network
  inbound_rule {
    protocol         = "udp"
    port_range       = "4789"
    source_addresses = ["10.0.0.0/8"]
  }

  ### ICMP for Ping ###
  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  ### Outbound Rules (Left open for now) ###
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
