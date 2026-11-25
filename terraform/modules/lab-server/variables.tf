variable "name" {
  description = "Name for the server and its resources"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.large"
}

variable "root_volume_gb" {
  description = "Root disk size in GB"
  type        = number
  default     = 30
}

variable "vpc_id" {
  description = "VPC where the server runs"
  type        = string
}

variable "subnet_id" {
  description = "Subnet where the server runs"
  type        = string
}

variable "ssh_cidr" {
  description = "Only this CIDR can SSH (your IP/32)"
  type        = string

  validation {
    condition     = var.ssh_cidr != "0.0.0.0/0"
    error_message = "SSH must not be open to the whole internet."
  }
}

variable "public_key" {
  description = "SSH public key content"
  type        = string
}
