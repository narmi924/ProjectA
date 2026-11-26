variable "do_ssh_key" {
  description = "Name of the controller's SSH public key in DigitalOcean."
  type        = string
  default     = "www-1"
}

variable "ssh_private_key" {
  description = "Absolute path to the matching private key on the Ansible controller."
  type        = string
}
