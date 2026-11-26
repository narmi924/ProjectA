variable "docker_host" {
  description = "Docker Machine's public IP address, as listed by docker-machine ip docker-nginx."
  type        = string
}

variable "docker_private_ip" {
  description = "Private IPv4 address of docker-nginx on the default SGP1 VPC."
  type        = string
}

variable "docker_cert_path" {
  description = "Directory holding Docker Machine's CA and client TLS certificate and key."
  type        = string
  default     = "~/.docker/machine/machines/docker-nginx"
}

variable "ssh_private_key" {
  description = "Path to the controller's SSH key for Nginx, with its public key alongside it (.pub)."
  type        = string
  default     = "~/.ssh/workshop4"
}

variable "backend_instance_count" {
  type    = number
  default = 3

  validation {
    condition     = var.backend_instance_count >= 1 && floor(var.backend_instance_count) == var.backend_instance_count
    error_message = "Use a positive whole number of backend containers."
  }
}
