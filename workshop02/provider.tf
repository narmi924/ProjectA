terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.26"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

# The provider reads DIGITALOCEAN_TOKEN from the controller's environment.
provider "digitalocean" {}
