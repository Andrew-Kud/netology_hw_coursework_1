#outputs показывает успешно созданные ресурсы после terraform apply
#terraform output или terraform output alb_public_ip
#ssh user@$(terraform output -raw bastion_public_ip)
#curl http://$(terraform output -raw alb_public_ip)


#внешний ip
output "alb_public_ip" {
  description = "public ip of alb"
  value       = yandex_alb_load_balancer.web_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}

output "bastion_public_ip" {
  description = "public ip of bastion host (SSH:22)"
  value       = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}

output "grafana_public_ip" {
  description = "public ip of grafana (http:3000)"
  value       = yandex_compute_instance.grafana.network_interface.0.nat_ip_address
}

output "kibana_public_ip" {
  description = "public ip of kibana (http:5601)"
  value       = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}



#локальные ip
output "web_b_internal_ip" {
  description = "local ip of web-server zone B"
  value       = yandex_compute_instance.web_b.network_interface.0.ip_address
}

output "web_d_internal_ip" {
  description = "local ip of web-server zone D"
  value       = yandex_compute_instance.web_d.network_interface.0.ip_address
}

output "prometheus_internal_ip" {
  description = "local ip of prometheus"
  value       = yandex_compute_instance.prometheus.network_interface.0.ip_address
}

output "elasticsearch_internal_ip" {
  description = "local ip of elasticsearch"
  value       = yandex_compute_instance.elastic.network_interface.0.ip_address
}

output "grafana_internal_ip" {
  description = "local ip of grafana"
  value       = yandex_compute_instance.grafana.network_interface.0.ip_address
}

output "kibana_internal_ip" {
  description = "local ip of kibana"
  value       = yandex_compute_instance.kibana.network_interface.0.ip_address
}



#общзая инфа в.т.ч связанные группы.
output "alb_info" {
  description = "ALB info"
  value = {
    name              = yandex_alb_load_balancer.web_alb.name
    id                = yandex_alb_load_balancer.web_alb.id
    public_ip         = yandex_alb_load_balancer.web_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
    backend_group_id  = yandex_alb_backend_group.web_bg.id
    target_group_id   = yandex_alb_target_group.web_tg.id
  }
}
output "snapshot_schedule_info" {
  description = "Snapshot info"
  value = {
    name            = yandex_compute_snapshot_schedule.daily_snapshots.name
    id              = yandex_compute_snapshot_schedule.daily_snapshots.id
    schedule        = yandex_compute_snapshot_schedule.daily_snapshots.schedule_policy[0].expression
    snapshot_count  = yandex_compute_snapshot_schedule.daily_snapshots.snapshot_count
    vms_count       = length(yandex_compute_snapshot_schedule.daily_snapshots.disk_ids)
  }
}
output "network_info" {
  description = "Network info"
  value = {
    vpc_id             = yandex_vpc_network.develop.id
    subnet_a_id        = yandex_vpc_subnet.develop_a.id
    subnet_b_id        = yandex_vpc_subnet.develop_b.id
    subnet_d_id        = yandex_vpc_subnet.develop_d.id
    nat_gateway_id     = yandex_vpc_gateway.nat_gateway.id
  }
}
#дополнительные команды (terraform output access_commands)
output "access_commands" {
  description = "Commands for accessing services"
  value = {
    website          = "curl -v http://${yandex_alb_load_balancer.web_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address}"
    grafana          = "http://${yandex_compute_instance.grafana.network_interface.0.nat_ip_address}:3000"
    kibana           = "http://${yandex_compute_instance.kibana.network_interface.0.nat_ip_address}:5601"
    bastion_ssh      = "ssh -l ${var.user_name} ${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}"
  }
}
#вывод сводки по всем вм
output "all_vms" {
  description = "Listing all VM"
  value = {
    bastion = {
      name        = yandex_compute_instance.bastion.name
      zone        = yandex_compute_instance.bastion.zone
      internal_ip = yandex_compute_instance.bastion.network_interface.0.ip_address
      public_ip   = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
    }
    web_b = {
      name        = yandex_compute_instance.web_b.name
      zone        = yandex_compute_instance.web_b.zone
      internal_ip = yandex_compute_instance.web_b.network_interface.0.ip_address
      public_ip   = "none (private)"
    }
    web_d = {
      name        = yandex_compute_instance.web_d.name
      zone        = yandex_compute_instance.web_d.zone
      internal_ip = yandex_compute_instance.web_d.network_interface.0.ip_address
      public_ip   = "none (private)"
    }
    prometheus = {
      name        = yandex_compute_instance.prometheus.name
      zone        = yandex_compute_instance.prometheus.zone
      internal_ip = yandex_compute_instance.prometheus.network_interface.0.ip_address
      public_ip   = "none (private)"
    }
    grafana = {
      name        = yandex_compute_instance.grafana.name
      zone        = yandex_compute_instance.grafana.zone
      internal_ip = yandex_compute_instance.grafana.network_interface.0.ip_address
      public_ip   = yandex_compute_instance.grafana.network_interface.0.nat_ip_address
    }
    elasticsearch = {
      name        = yandex_compute_instance.elastic.name
      zone        = yandex_compute_instance.elastic.zone
      internal_ip = yandex_compute_instance.elastic.network_interface.0.ip_address
      public_ip   = "none (private)"
    }
    kibana = {
      name        = yandex_compute_instance.kibana.name
      zone        = yandex_compute_instance.kibana.zone
      internal_ip = yandex_compute_instance.kibana.network_interface.0.ip_address
      public_ip   = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
    }
  }
}
