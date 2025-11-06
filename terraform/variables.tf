variable "flow" {
  type    = string
  default = "kursach-11-2025"
}


#3_для providers.tf
variable "cloud_id" {
  type    = string
}
variable "folder_id" {
  type    = string
}


#переменные для ресурсов вм в main.tf
variable "vm_project" {
  type = map(number)
  default = {
    cores         = 2
    memory        = 1
    core_fraction = 20
    #disk
    #type     = "network-hdd" #нужно выновить в отдельную переменную type = string \ default = "network-hdd"
    size     = 10
  }
}


#защита cloud-init.yml
variable "user_name" {
  type = string
}
variable "public_ssh_key" {
  type = string
}
