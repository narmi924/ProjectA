resource "docker_network" "bgg" {
  name = "bgg-net"
}

resource "docker_volume" "database" {
  name = "bgg-data"
}

resource "docker_image" "database" {
  name = "chukmunnlee/bgg-database:v3.1"
}

resource "docker_container" "database" {
  name         = "bgg-database"
  image        = docker_image.database.image_id
  restart      = "unless-stopped"
  wait         = true
  wait_timeout = 300

  # Leave memory for three Node.js processes on the 1 GiB course Droplet.
  command = ["mysqld", "--innodb-buffer-pool-size=64M", "--performance-schema=OFF", "--max-connections=40"]

  healthcheck {
    test         = ["CMD", "mysqladmin", "ping", "--protocol=tcp", "--host=127.0.0.1", "--silent"]
    interval     = "10s"
    timeout      = "3s"
    start_period = "5s"
    retries      = 30
  }

  networks_advanced {
    name = docker_network.bgg.name
  }

  volumes {
    volume_name    = docker_volume.database.name
    container_path = "/var/lib/mysql"
  }

  ports {
    internal = 3306
    external = 3306
    ip       = "127.0.0.1"
  }
}

resource "docker_image" "backend" {
  name = "chukmunnlee/bgg-backend:v3"
}

resource "docker_container" "backend" {
  count   = var.backend_instance_count
  name    = "bgg-backend-${count.index + 1}"
  image   = docker_image.backend.image_id
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.bgg.name
  }

  env = [
    "BGG_DB_USER=root",
    "BGG_DB_PASSWORD=changeit",
    "BGG_DB_HOST=${docker_container.database.name}",
  ]

  ports {
    internal = 3000
    external = 3001 + count.index
    ip       = var.docker_private_ip
  }
}

locals {
  backend_endpoints = [for backend in docker_container.backend : "${var.docker_private_ip}:${backend.ports[0].external}"]
}

resource "local_file" "nginx_conf" {
  filename = "${path.module}/nginx.conf"
  content = templatefile("${path.module}/sample.nginx.conf.tftpl", {
    endpoints = local.backend_endpoints
  })
}

resource "digitalocean_ssh_key" "controller" {
  name       = "workshop4-nginx"
  public_key = trimspace(file(pathexpand("${var.ssh_private_key}.pub")))
}

resource "digitalocean_droplet" "nginx" {
  name     = "nginx"
  image    = "ubuntu-24-04-x64"
  region   = "sgp1"
  size     = "s-1vcpu-512mb-10gb"
  ssh_keys = [digitalocean_ssh_key.controller.fingerprint]
}

resource "terraform_data" "configure_nginx" {
  triggers_replace = [digitalocean_droplet.nginx.id, local_file.nginx_conf.content_sha256]

  connection {
    type        = "ssh"
    host        = digitalocean_droplet.nginx.ipv4_address
    user        = "root"
    private_key = file(pathexpand(var.ssh_private_key))
  }

  provisioner "file" {
    source      = local_file.nginx_conf.filename
    destination = "/root/workshop4-nginx.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "set -eu",
      "cloud-init status --wait || test $? -eq 2",
      "apt-get -o DPkg::Lock::Timeout=180 update -qq",
      "DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=180 install -y nginx",
      "nginx -t -c /root/workshop4-nginx.conf",
      "install -m 0644 /root/workshop4-nginx.conf /etc/nginx/nginx.conf",
      "systemctl enable nginx && systemctl restart nginx",
    ]
  }
}

resource "local_file" "root_at_nginx" {
  filename        = "${path.module}/root@${digitalocean_droplet.nginx.ipv4_address}"
  content         = ""
  file_permission = "0444"
}

output "nginx_ip" {
  value      = digitalocean_droplet.nginx.ipv4_address
  depends_on = [terraform_data.configure_nginx]
}

output "backend_endpoints" {
  value = local.backend_endpoints
}
