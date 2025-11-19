#target группа веб серверов.
resource "yandex_alb_target_group" "web_tg" {
  name = "web-target-group-${var.flow}"

  #web-b
  target {
    subnet_id  = yandex_vpc_subnet.develop_b.id #подсеть где расположен сервер.
    ip_address = yandex_compute_instance.web_b.network_interface.0.ip_address #айпишник сервера в этой подсети.
  }
  #web-d
  target {
    subnet_id  = yandex_vpc_subnet.develop_d.id
    ip_address = yandex_compute_instance.web_d.network_interface.0.ip_address
  }
  #зависимость, сначала создадуться веб сервера, потом группа.
  depends_on = [
    yandex_compute_instance.web_b,
    yandex_compute_instance.web_d
  ]
}



# backend група с healhcheck
resource "yandex_alb_backend_group" "web_bg" {
  name = "web-backend-group-${var.flow}"
  http_backend {
    name             = "web-backend"
    weight           = 1 #вес сервера при распределении. одинаковый для обоих серверов.
    port             = 80 #порт для трафика проверки
    target_group_ids = [yandex_alb_target_group.web_tg.id] #к какой группе принадлежит backend
    #порог паники в 50% отказа серверов, дальше будет направлять трафик на все бэкэнды без фильтрации.
    load_balancing_config {
      panic_threshold = 50
    }
    #правила проверки жизнесособности серверов
    healthcheck {
      timeout             = "1s"
      interval            = "5s"
      healthy_threshold   = 3
      unhealthy_threshold = 3
      http_healthcheck {
        path = "/"  #проверка http-get на корень сайта
      }
    }
  }
}



#роутер http запросв
resource "yandex_alb_http_router" "web_router" {
  name = "web-http-router-${var.flow}"
}



#сущность для обработки http запросов. привязан к http роутеру выше
resource "yandex_alb_virtual_host" "web_vhost" {
  name           = "web-virtual-host-${var.flow}"
  http_router_id = yandex_alb_http_router.web_router.id
  # маршрут направляющий весь http трафик на backend группу.
  route {
    name = "web-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_bg.id
        timeout          = "60s" #время ожидания ответа от бэкэнд группы.
      }
    }
  }
}



#балансировщик нагрузки http
resource "yandex_alb_load_balancer" "web_alb" {
  name       = "web-alb-${var.flow}" #имя ресурса
  network_id = yandex_vpc_network.develop.id #сеть, в которой будет работать балансировщик.
  #размещает балансировщик в нескольких зонах.
  allocation_policy {
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.develop_b.id
    }
    location {
      zone_id   = "ru-central1-d"
      subnet_id = yandex_vpc_subnet.develop_d.id
    }
  }
  #слушает http
  listener {
    name = "web-listener"
    endpoint {
      address {
        external_ipv4_address {
          #автовыделение внешнего айпишника.
        }
      }
      ports = [80] #порт прослушивания
    }
    #обработчик передающий http -> http_router_id
    http {
      handler {
        http_router_id = yandex_alb_http_router.web_router.id
      }
    }
  }
  #какая sg применяется для alb.
  security_group_ids = [
    yandex_vpc_security_group.alb_sg.id
  ]
  #роутер и бэкэнд группа будут созданы до балансировшика.
  depends_on = [
    yandex_alb_http_router.web_router,
    yandex_alb_backend_group.web_bg
  ]
}
