#расписание для создания снапшотов.


#общее расписание снапшотов
resource "yandex_compute_snapshot_schedule" "daily_snapshots" {
  name = "daily-snapshots-${var.flow}"

  #политика расписания (каждой день в 2 по UTC или 5 по МСК)
  schedule_policy {
    expression = "0 2 * * *"
  }

  snapshot_count = 7  #макс кол-во снимков

  #наткнулся на рекомендации оставлять метки для снапшотов, добавил, хз надо-нет.
  snapshot_spec {
    description = "auto-daily snapshot for ${var.flow}"
    labels = {
      environment = "production"
      managed_by  = "terraform"
      project     = var.flow
    }
  }

  # список ВМ(диски, не как в qemu, тут нужно указать disk_id бут диска каждой вм) для резервного копирования
  disk_ids = [
    yandex_compute_instance.bastion.boot_disk.0.disk_id,
    yandex_compute_instance.web_d.boot_disk.0.disk_id,
    yandex_compute_instance.web_b.boot_disk.0.disk_id,
    yandex_compute_instance.prometheus.boot_disk.0.disk_id,
    yandex_compute_instance.grafana.boot_disk.0.disk_id,
    yandex_compute_instance.elastic.boot_disk.0.disk_id,
    yandex_compute_instance.kibana.boot_disk.0.disk_id
  ]

  #зависимости, перед созданием расписания снапшотов убедиться, что все перечисленные вм созданы.
  #тераформ может создать расписание снапшотов несуществующих вм и яндекс примет?
  depends_on = [
    yandex_compute_instance.bastion,
    yandex_compute_instance.web_d,
    yandex_compute_instance.web_b,
    yandex_compute_instance.prometheus,
    yandex_compute_instance.grafana,
    yandex_compute_instance.elastic,
    yandex_compute_instance.kibana
  ]
}


# нашёл вариант ещё с отдельным расписание для сервисов
# resource "yandex_compute_snapshot_schedule" "critical_services_snapshots" {
#   name = "critical-services-${var.flow}"
#
#   schedule_policy {
#     expression = "0 */6 * * *"  # каждые 6 часов
#   }
#
#   retention_period = "168h"  # 7 дней
#
#   snapshot_spec {
#     description = "High-frequency snapshots for critical services"
#     labels = {
#       priority   = "critical"
#       managed_by = "terraform"
#     }
#   }
#
#   disk_ids = [
#     yandex_compute_instance.prometheus.boot_disk.0.disk_id,
#     yandex_compute_instance.elastic.boot_disk.0.disk_id
#   ]
# }
