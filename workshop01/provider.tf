terraform {
  required_version = ">= 1.4"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.7"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.26"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
  }
}

provider "docker" {
  host      = "tcp://${var.docker_host}:2376"
  cert_path = pathexpand(var.docker_cert_path)
}

# The DigitalOcean provider reads DIGITALOCEAN_TOKEN from the controller.
provider "digitalocean" {}
