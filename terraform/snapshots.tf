#общее расписание снапшотов
resource "yandex_compute_snapshot_schedule" "daily_snapshots" {
  name = "daily-snapshots-${var.flow}"

  #политика расписания (каждой день в 2 по UTC или 5 по МСК)
  schedule_policy {
    expression = "0 2 * * *"
  }

  snapshot_count = 7  #макс кол-во снимков
  retention_period = "168h"  #каждый живёт максимум 7 дней

  #метки для снапшотов
  snapshot_spec {
    description = "auto-daily snapshot for ${var.flow}"
    labels = {
      environment = "production"
      managed_by  = "terraform"
      project     = var.flow
    }
  }

  # список ВМ для резервного копирования
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
