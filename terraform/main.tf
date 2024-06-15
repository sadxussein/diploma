terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-a"
}

# ------------------------------------------ NETWORKING -----------------------------------------------
# Создание VPC
resource "yandex_vpc_network" "main" {
  name = "main-network"
}

# Создание публичной подсети
resource "yandex_vpc_subnet" "private-a" {
  name           = "private-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.2.0/24"]
}

resource "yandex_vpc_subnet" "private-b" {
  name           = "private-subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.3.0/24"]
}

# Создание приватной подсети
resource "yandex_vpc_subnet" "public" {
  name           = "public-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.4.0/24"]
}

# ------------------------------------------ SECURITY GROUPS ------------------------------------------
# Security Group для веб-серверов
resource "yandex_vpc_security_group" "web" {
  name       = "web-security-group"
  network_id = yandex_vpc_network.main.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 1
    to_port        = 65535
  }

  ingress {
    description    = "Allow HTTP"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Allow SSH from Bastion"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = [yandex_vpc_subnet.public.v4_cidr_blocks[0]]
  }

  ingress {
    description    = "Allow zabbix agent"
    protocol       = "TCP"
    port           = 10050
    v4_cidr_blocks = [yandex_vpc_subnet.public.v4_cidr_blocks[0]]
  }

  ingress {
    description       = "healthchecks"
    protocol          = "TCP"
    port              = 30080
    predefined_target = "loadbalancer_healthchecks"    
  }
}

# Security Group для Elasticsearch
resource "yandex_vpc_security_group" "elasticsearch" {
  name       = "elasticsearch-security-group"
  network_id = yandex_vpc_network.main.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 1
    to_port        = 65535
  }

  ingress {
    description    = "Allow elastic traffic"
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = ["10.0.3.0/24"]
  }

  ingress {
    description    = "Allow logstash traffic from web servers"
    protocol       = "TCP"
    port           = 5044
    v4_cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
  }
  
  ingress {
    description    = "Allow SSH from Bastion"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = [yandex_vpc_subnet.public.v4_cidr_blocks[0]]
  }
}

# Security Group для публичных сервисов (Zabbix, Kibana, Load Balancer)
resource "yandex_vpc_security_group" "public_services" {
  name       = "public-services-security-group"
  network_id = yandex_vpc_network.main.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 1
    to_port        = 65535
  }

  ingress {
    description    = "Allow HTTP"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Allow HTTPS"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Allow Zabbix"
    protocol       = "TCP"
    port           = 10050
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Allow SSH"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }  
}

# Security Group для Bastion Host
resource "yandex_vpc_security_group" "bastion" {
  name       = "bastion-security-group"
  network_id = yandex_vpc_network.main.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 1
    to_port        = 65535
  }

  ingress {
    description    = "Allow SSH"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description    = "Allow http/s proxy from Bastion"
    protocol       = "TCP"
    port           = 8888
    v4_cidr_blocks = [yandex_vpc_subnet.public.v4_cidr_blocks[0]]
  }
}

# ------------------------------------------ VIRTUAL MACHINES -----------------------------------------
# resource "yandex_compute_instance" "vm" {
#   for_each = {
#     "bastion" = { name = "bastion", zone = "ru-central1-a", hostname = "bastion", subnet_id = yandex_vpc_subnet.public.id},
#     "web-server-1" = { name = "web-server-1", zone = "ru-central1-a", hostname = "web-server-1", subnet_id = yandex_vpc_subnet.private-a.id},
#     "web-server-2" = { name = "web-server-2", zone = "ru-central1-b", hostname = "web-server-2", subnet_id = yandex_vpc_subnet.private-b.id},
#     "elasticsearch" = { name = "elasticsearch", zone = "ru-central1-a", hostname = "elasticsearch", subnet_id = yandex_vpc_subnet.private-a.id},
#     "kibana" = { name = "kibana", zone = "ru-central1-a", hostname = "kibana", subnet_id = yandex_vpc_subnet.public.id},
#     "zabbix" = { name = "zabbix", zone = "ru-central1-a", hostname = "zabbix", subnet_id = yandex_vpc_subnet.public.id},
#   }

#   name = each.value.name  
#   hostname = each.value.hostname
#   zone = each.value.zone  
#   platform_id = "standart-v2"

#   resources {
#     cores  = 2
#     memory = 2
#   }

#   boot_disk {
#     initialize_params {
#       image_id = "fd8re3hiqnikqr7j7m8s"  # Ubuntu 22.04 LTS
#     }
#   }

#   network_interface {
#     subnet_id = each.value.subnet_id
#     nat       = true
#   }

#   scheduling_policy {
#     preemptible = true
#   }

#   metadata = {
#     ssh-keys = "xussein:${file(var.ssh_public_key_path)}"
#   }
# }
# Bastion Host
resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  zone        = "ru-central1-a"
  platform_id = "standard-v2"
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = "fd8re3hiqnikqr7j7m8s"  # Ubuntu 22.04 LTS
      # image_id = "fd806u1okplml22f4pmo"  # Ubuntu 22.04 LTS NAT
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
  }
  hostname = "bastion"
  scheduling_policy {
    preemptible = true
  }
  metadata = {
    ssh-keys = "xussein:${file(var.ssh_public_key_path)}"
  }
}

# Веб-сервер 1
resource "yandex_compute_instance" "web_server_1" {
  name        = "web-server-1"
  zone        = "ru-central1-a"
  platform_id = "standard-v2"
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = "fd8re3hiqnikqr7j7m8s"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.private-a.id
  }
  hostname = "web-server-1"
  scheduling_policy {
    preemptible = true
  }
  metadata = {
    ssh-keys = "xussein:${file(var.ssh_public_key_path)}"
  }
}

# Веб-сервер 2
resource "yandex_compute_instance" "web_server_2" {
  name        = "web-server-2"
  zone        = "ru-central1-b"
  platform_id = "standard-v2"
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = "fd8re3hiqnikqr7j7m8s"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.private-b.id
  }
  hostname = "web-server-2"
  scheduling_policy {
    preemptible = true
  }
  metadata = {
    ssh-keys = "xussein:${file(var.ssh_public_key_path)}"
  }
}

# Elasticsearch сервер
resource "yandex_compute_instance" "elasticsearch" {
  name        = "elasticsearch"
  zone        = "ru-central1-a"
  platform_id = "standard-v2"
  resources {
    cores  = 2
    memory = 4
  }
  boot_disk {
    initialize_params {
      image_id = "fd8re3hiqnikqr7j7m8s"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.private-a.id
  }
  hostname = "elasticsearch"
  scheduling_policy {
    preemptible = true
  }
  metadata = {
    ssh-keys = "xussein:${file(var.ssh_public_key_path)}"
  }
}

# Zabbix сервер
resource "yandex_compute_instance" "zabbix" {
  name        = "zabbix"
  zone        = "ru-central1-a"
  platform_id = "standard-v2"
  resources {
    cores  = 2
    memory = 4
  }
  boot_disk {
    initialize_params {
      image_id = "fd8re3hiqnikqr7j7m8s"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
  }
  hostname = "zabbix"
  scheduling_policy {
    preemptible = false
  }
  metadata = {
    ssh-keys = "xussein:${file(var.ssh_public_key_path)}"
  }
}

# Kibana сервер
resource "yandex_compute_instance" "kibana" {
  name        = "kibana"
  zone        = "ru-central1-a"
  platform_id = "standard-v2"
  resources {
    cores  = 2
    memory = 4
  }
  boot_disk {
    initialize_params {
      image_id = "fd8re3hiqnikqr7j7m8s"
    }
  }
  hostname = "kibana"
  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
  }
  scheduling_policy {
    preemptible = false
  }
  metadata = {
    ssh-keys = "xussein:${file(var.ssh_public_key_path)}"
  }
}

# ------------------------------------------ LOAD BALANCER --------------------------------------------
# Target Group для веб-серверов
resource "yandex_alb_target_group" "web_servers_target_group" {
  name      = "web-servers-target-group"

  target {
    ip_address  = yandex_compute_instance.web_server_1.network_interface[0].ip_address
    subnet_id = yandex_vpc_subnet.private-a.id
  }

  target {
    ip_address  = yandex_compute_instance.web_server_2.network_interface[0].ip_address
    subnet_id = yandex_vpc_subnet.private-b.id
  }
}

# Backend Group для веб-серверов
resource "yandex_alb_backend_group" "web_servers_backend_group" {
  name      = "web-servers-backend-group"

  http_backend {
    name = "http-backend"
    port = 80    
    target_group_ids = [yandex_alb_target_group.web_servers_target_group.id]

    healthcheck {
      timeout = "10s"
      interval = "2s"
      healthcheck_port = 80
      http_healthcheck {
        path = "/"
      }
    }
  }
}

# HTTP Router
resource "yandex_alb_http_router" "http_router" {
  name      = "http-router"
}

resource "yandex_alb_virtual_host" "name" {
  name = "alb-host"
  http_router_id = yandex_alb_http_router.http_router.id
  route {
    name = "main-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_servers_backend_group.id
      }
    }
  }
}

# Application Load Balancer
resource "yandex_alb_load_balancer" "application_load_balancer" {
  name = "alb-main"
  network_id = yandex_vpc_network.main.id
  # security_group_ids = [yandex_vpc_security_group.web.id]

  allocation_policy {
    location {
      zone_id = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.private-a.id
    }

    location {
      zone_id = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.private-b.id
    }
  }

  listener {
    name = "alb-listener"
    endpoint {
      address {
        external_ipv4_address {          
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.http_router.id
      }
    }
  }
}

# ------------------------------------------ DISK SNAPSHOTS -------------------------------------------
# output "instance_disk_ids" {
#   value = [for vm in yandex_compute_instance.vm : vm.boot_disk.0.disk_id]
# }

resource "yandex_compute_snapshot_schedule" "default" {
  name = "daily-snapshots"

  schedule_policy {
    expression = "0 2 * * *"
  }

  snapshot_count = 5 

  snapshot_spec {
    description = "Daily snapshot"    
  }

  disk_ids = [
    yandex_compute_instance.bastion.boot_disk.0.disk_id, 
    yandex_compute_instance.web_server_1.boot_disk.0.disk_id,
    yandex_compute_instance.web_server_2.boot_disk.0.disk_id,
    yandex_compute_instance.elasticsearch.boot_disk.0.disk_id,
    yandex_compute_instance.kibana.boot_disk.0.disk_id,
    yandex_compute_instance.zabbix.boot_disk.0.disk_id
  ]
}

# ------------------------------------------ BASTION IP ADDRESS ---------------------------------------
output "bastion_ip_address" {
  value = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}

resource "local_file" "external_ip_file" {
  filename = "/home/xussein/yc/bastion_ip.txt"
  content = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}