data "digitalocean_ssh_key" "controller" {
  name = var.do_ssh_key
}

resource "digitalocean_droplet" "codeserver" {
  name     = "codeserver"
  region   = "sgp1"
  image    = "ubuntu-22-04-x64"
  size     = "s-1vcpu-1gb"
  ssh_keys = [data.digitalocean_ssh_key.controller.id]
}

resource "local_file" "inventory" {
  filename        = "${path.module}/inventory.yaml"
  file_permission = "0600"
  content = templatefile("${path.module}/inventory.yaml.tftpl", {
    codeserver_ip   = digitalocean_droplet.codeserver.ipv4_address
    ssh_private_key = var.ssh_private_key
  })
}

output "codeserver_ip" {
  value = digitalocean_droplet.codeserver.ipv4_address
}
