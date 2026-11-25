variable "region" {
  description = " AWS region"
  type        = string
  default     = "us-east-1"
}
variable "project" {
  description = "Project name used in the resource name"
  type        = string
  default     = "ai-gateway"
}

variable "my_ip_cidr" {
  description = "Your public IP with /32 (set in terraform.tfvars)"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}
