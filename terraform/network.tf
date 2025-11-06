#создание vpc сеть (основная для всех ресурсов, изолированная сеть, внутри неё будут работать все вмки, подсети, роуты)
resource "yandex_vpc_network" "develop" {
  name = "develop-fops-${var.flow}" # Имя сети. К ней будут подключени подсети из разных хон доступности. var.flow динамический параметр из variables.tf
}



#Создание подсетей в разных донах доступности (сделал в каждой)
#эти подсети, часть vpc созданной выше, но с собственным диапазоном.
# Создаем подсеть zone A.
resource "yandex_vpc_subnet" "develop_a" {
  name           = "develop-fops-${var.flow}-ru-central1-a" # Имя в yandex cloud.
  zone           = "ru-central1-a" #сама зона доступности
  network_id     = yandex_vpc_network.develop.id #связывает подсеть с общей vpc (в самом верху)
  v4_cidr_blocks = ["10.0.1.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id # ссылается на тамблицу маршрутизации (ниже создаём).
}

# Создаем подсеть zone B.
resource "yandex_vpc_subnet" "develop_b" {
  name           = "develop-fops-${var.flow}-ru-central1-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = ["10.0.2.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}

# Создаем подсеть zone D.
resource "yandex_vpc_subnet" "develop_d" {
  name           = "develop-fops-${var.flow}-ru-central1-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = ["10.0.3.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}



#создание NAT шлюза, для доступа ВМ в интернет из локальной сети (vpc).
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "fops-gateway-${var.flow}"
  shared_egress_gateway {} # Выход во внешнюю сеть, включение NAT. ingress - Входящий к ВМ, egress - Исходящий от ВМ.value
}

#Сама таблица маршрутизации для выхода в интернет через нат (определяется куда направлять интернет трафик)
resource "yandex_vpc_route_table" "rt" {
  name       = "fops-route-table-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  # Таблица маршрутизации.
  static_route {
    destination_prefix = "0.0.0.0/0" # Маршрут по умолчанию.
    gateway_id         = yandex_vpc_gateway.nat_gateway.id # Куда будет смотреть 0.0.0.0/0 -> nat_gateway созданный чуть выше.
  }
}


#группы безопасности или sg, по сути фаерволл для ВМ.
#bastion
resource "yandex_vpc_security_group" "bastion" {
  name       = "bastion-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  ingress {
    description    = "Allow 0.0.0.0/0"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"] # С каких ip из интернета можно получить доступ к bastion
    port           = 22 #по какому порту будет доступ к Bastion
  }
  egress {
    # Разрешон весь исходящий трафик по всем портам и протоколам.
    description    = "Permit ANY"
    protocol       = "ANY" #по какому протоколу (tcp/udp и.т.д). в данном случае - со всех протоколов.
    v4_cidr_blocks = ["0.0.0.0/0"] #разрешает любой исходящий трафик
    from_port      = 0 #с диапазона портов (по сути со всех портов)
    to_port        = 65535
  }
}



#локальная сеть для доступа ВМ друг к другу..
resource "yandex_vpc_security_group" "LAN" {
  name       = "LAN-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  ingress {
    # Разрешить любой входящий трафик только от 10.0.0.0/8.
    description    = "Allow 10.0.0.0/8"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.0.0.0/8"]
    from_port      = 0
    to_port        = 65535
  }
  egress {
    # Разрешить любой исходящий трафик.
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}



# Группа для веб-серверов.
resource "yandex_vpc_security_group" "web_sg" {
  name       = "web-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  description = "security group for web-srv - traffic"
  #web-ethernet
  ingress {
    description    = "Allow HTTPS"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description    = "Allow HTTP"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  # Входящий трафик из lan
  ingress {
    description    = "Allow 10.0.0.0/8"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.0.0.0/8"]
    from_port      = 0
    to_port        = 65535
  }
  #Исходящий трафик.
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}



#группа для балансировщика (alb)
resource "yandex_vpc_security_group" "alb_sg" {
  name       = "alb-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  description = "security group for ALB"
  #web-ethernet
  ingress {
    description    = "allow http and healthchecks"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description    = "allow https and healthchecks"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description    = "Health checks from Yandex Cloud"
    protocol       = "TCP"
    from_port      = 0
    to_port        = 65535
    #так делать не надо, но я перепробовал все ip из документации и ни один не подошёл.
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Исходящий трафик.
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}



#prometheus
resource "yandex_vpc_security_group" "prometheus_sg" {
  name       = "prometheus-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  description = "security group for prometheus"
  #позволяет получать метрики из всех локальных подсетей 10.
  ingress {
    description    = "Allow 10.0.0.0/8"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.0.0.0/8"]
    from_port      = 0
    to_port        = 65535
  }
  # Исходящий трафик
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}



#grafana
resource "yandex_vpc_security_group" "grafana_sg" {
  name       = "grafana-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  description = "security group for grafana"
  #открывает входящий web-трафик на 3000 из интернета.
  ingress {
    description    = "allow grafana from internet"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 3000
  }
  # Исходящий трафик,
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}



#elastik
resource "yandex_vpc_security_group" "elasticsearch_sg" {
  name       = "elasticsearch-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  description = "security group for elasticsearch"
  # Входящий трафик для kibana и filebeat
  ingress {
    description    = "Allow 10.0.0.0/8"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.0.0.0/8"]
    from_port      = 0
    to_port        = 65535
  }
  # Исходящий трафик.
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}



#kibana
resource "yandex_vpc_security_group" "kibana_sg" {
  name       = "kibana-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  description = "security group for kibana"
  #открывает входящий web-трафик на порт 5601 из интернета
  ingress {
    description    = "allow kibana from intenet"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }
  # Исходящий трафик
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}
