variable "khoa_ssh_public_key" {
  description = "Khoa's SSH Public Key"
  type        = string
}

variable "anh_ssh_public_key" {
  description = "Tieu Anh's SSH Public Key"
  type        = string
}

variable "phong_ssh_public_key" {
  description = "Phong's SSH Public Key"
  type        = string
}

variable "custom_ssh_port" {
  description = "Custom SSH Port"
  type        = string
}

variable "ssh_access_ips" {
  description = "List of CIDR blocks allowed to access SSH"
  type        = list(string)
}

variable "domain_name" {
  description = "Domain name managed by Cloudflare"
  type        = string
}
variable "subdomain_name" {
  description = "Subdomain name for the Load Balancer"
  type        = string
}

variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
  sensitive   = true
}

variable "cloudflare_ipv4" {
  description = "Cloudflare IPv4 CIDR blocks"
  type        = list(string)
}
