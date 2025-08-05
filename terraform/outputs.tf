# === Outputs ===

# --- Manager Node IP ---
output "manager_ip" {
  description = "Public IP address of the manager node"
  value       = digitalocean_droplet.manager.ipv4_address
}

# --- Worker Node IPs ---
output "worker_ips" {
  description = "List of public IP addresses of worker nodes"
  value       = [for worker in digitalocean_droplet.workers : worker.ipv4_address]
}

# --- Load Balancer IP ---
output "load_balancer_ip" {
  description = "Public IP address of the DigitalOcean load balancer"
  value       = digitalocean_loadbalancer.nodes.ip
}

# --- DNS Record ---
output "dns_record_name" {
  description = "FQDN of the subdomain"
  value       = var.domain_name
}

# --- Droplet IDs ---
output "manager_droplet_id" {
  description = "DigitalOcean droplet ID for the manager node"
  value       = digitalocean_droplet.manager.id
}

output "worker_droplet_ids" {
  description = "List of droplet IDs for worker nodes"
  value       = [for w in digitalocean_droplet.workers : w.id]
}

# --- All Droplet IPs (combined) ---
output "all_droplet_ips" {
  description = "List of all droplet IPs (manager + workers)"
  value = concat(
    [digitalocean_droplet.manager.ipv4_address],
    [for w in digitalocean_droplet.workers : w.ipv4_address]
  )
}
