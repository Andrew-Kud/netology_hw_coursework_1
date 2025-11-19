#конфигурационный файл, указывают настройки подключения к облачным провайдерам и другим системам, с помощью которых Terraform будет создавать и управлять ресурсами.
#управляет аутентификацией и связью terraform с облаком.
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.129.0"
    }
  }
  required_version = ">=1.8.4"
}



#источник для авторизации (ключи от сервисного аккаунта yandex cloud)
provider "yandex" {
  # token                    = "do not use!!!"
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  service_account_key_file = file(var.authorized_key)
}
