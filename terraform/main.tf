#выбор образа для ОС.
data "yandex_compute_image" "ubuntu_2404_lts" {
  family = "ubuntu-2404-lts"
}


#защита cloud-init.yml
data "template_file" "cloud_init" {
  template = file("${path.module}/cloud-init.tpl")

  vars = {
    user_name      = var.user_name
    public_ssh_key = var.public_ssh_key
  }
}


#Bastion
resource "yandex_compute_instance" "bastion" {
  name        = "bastion" #Имя ВМ в yandex cloud
  hostname    = "bastion" #имя хоста внутри ОС
  platform_id = "standard-v3" #тип платформы
  zone        = "ru-central1-a" #Зона ВМ должна совпадать с зоной subnet.

  #ресурсы для вм (вывел в переменные, которые живут в variables.tf)
  resources {
    cores         = var.vm_project.cores
    memory        = var.vm_project.memory
    core_fraction = var.vm_project.core_fraction
  }

  #диск загрузки ос, который был указан в самом начале main.tf
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-hdd"
      size     = var.vm_project.size
    }
  }

  metadata = {
    user-data          = file("${path.module}/cloud-init.yml") #Отправка инструкций в создающуюся ВМ, те, что прописаны в cloud-init.yml
    serial-port-enable = 1 #включить порт отладки?
  }

  scheduling_policy { preemptible = true } # Прерываемая ВМ.

  # сетевая конфигурация.
  network_interface {
    subnet_id          = yandex_vpc_subnet.develop_a.id #подсеть, куда подключается ВМ.
    nat                = true #есть выход в интернет
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.bastion.id] #какие группы безопасности применяются к сетевому интерфейсу этой ВМки.
  }

  #зависимости, создание security group перед созданием ВМ.
  depends_on = [
    yandex_vpc_security_group.LAN,
    yandex_vpc_security_group.bastion,
  ]
}



#web_d
resource "yandex_compute_instance" "web_d" {
  name        = "web-d"
  hostname    = "web-d"
  platform_id = "standard-v3"
  zone        = "ru-central1-d"

  resources {
    cores         = var.vm_project.cores
    memory        = var.vm_project.memory
    core_fraction = var.vm_project.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-hdd"
      size     = var.vm_project.size
    }
  }

  metadata = {
    user-data          = file("${path.module}/cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.develop_d.id
    nat                = false #Нет прямого выхода в интернет.
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.web_sg.id]
  }

  depends_on = [
    yandex_vpc_security_group.LAN,
    yandex_vpc_security_group.bastion,
  ]
}



#web_b
resource "yandex_compute_instance" "web_b" {
  name        = "web-b"
  hostname    = "web-b"
  platform_id = "standard-v3"
  zone        = "ru-central1-b"

  resources {
    cores         = var.vm_project.cores
    memory        = var.vm_project.memory
    core_fraction = var.vm_project.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-hdd"
      size     = var.vm_project.size
    }
  }

  metadata = {
    user-data          = file("${path.module}/cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.develop_b.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.web_sg.id]
  }

  depends_on = [
    yandex_vpc_security_group.LAN,
    yandex_vpc_security_group.bastion,
  ]
}



#prometheus
resource "yandex_compute_instance" "prometheus" {
  name        = "prometheus"
  hostname    = "prometheus"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  #нагуглил, больше мощностей, по этому не завернул в переменные, как для бастиона и вебок.
  resources {
    cores         = 2
    memory        = 4
    core_fraction = 50
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-ssd"
      size     = 20
    }
  }

  metadata = {
    user-data          = file("${path.module}/cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.develop_a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.prometheus_sg.id]
  }

  depends_on = [
    yandex_vpc_security_group.LAN,
    yandex_vpc_security_group.prometheus_sg,
  ]
}



#grafana
resource "yandex_compute_instance" "grafana" {
  name        = "grafana"
  hostname    = "grafana"
  platform_id = "standard-v3"
  zone        = "ru-central1-b"

  resources {
    cores         = var.vm_project.cores
    memory        = 2
    core_fraction = 50
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-hdd"
      size     = var.vm_project.size
    }
  }

  metadata = {
    user-data          = file("${path.module}/cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.develop_b.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.grafana_sg.id]
  }

  depends_on = [
    yandex_vpc_security_group.LAN,
    yandex_vpc_security_group.grafana_sg,
  ]
}



#elastic
resource "yandex_compute_instance" "elastic" {
  name        = "elastic"
  hostname    = "elastic"
  platform_id = "standard-v3"
  zone        = "ru-central1-b"

  resources {
    cores         = 4
    memory        = 8
    core_fraction = var.vm_project.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-ssd"
      size     = 50
    }
  }

  metadata = {
    user-data          = file("${path.module}/cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.develop_b.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.elasticsearch_sg.id]
  }

  depends_on = [
    yandex_vpc_security_group.LAN,
    yandex_vpc_security_group.elasticsearch_sg,
  ]
}



#kibana
resource "yandex_compute_instance" "kibana" {
  name        = "kibana"
  hostname    = "kibana"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = var.vm_project.cores
    memory        = 2
    core_fraction = 50
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-hdd"
      size     = var.vm_project.size
    }
  }

  metadata = {
    user-data          = file("${path.module}/cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.develop_a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.kibana_sg.id]
  }

  depends_on = [
    yandex_vpc_security_group.LAN,
    yandex_vpc_security_group.kibana_sg,
  ]
}


# локальный файл для ansible - кажется это инверторизации для подключения к ВМ для ansible.
# в webservers указаны локальные ip вмок, к ним нужно обращаться через bastion ssh проксю.
# наверное нужен что бы упростить ансибл плейбуков.
resource "local_file" "inventory" {
  content  = <<-XYZ
  [bastion]
  ${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}

  [webservers]
  ${yandex_compute_instance.web_d.network_interface.0.ip_address}
  ${yandex_compute_instance.web_b.network_interface.0.ip_address}
  [webservers:vars]
  ansible_ssh_common_args='-o ProxyCommand="ssh -p 22 -W %h:%p -q user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}"'
  XYZ
  filename = "./hosts.ini"
}
