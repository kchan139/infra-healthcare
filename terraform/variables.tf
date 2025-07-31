variable "khoa_ssh_public_key" {
  description = "Khoa's SSH Public Key"
  type        = string
}

variable "anh_ssh_public_key" {
  description = "Tieu Anh's SSH Public Key"
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
