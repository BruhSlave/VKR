# Local values
locals {
  boot_disk_name      = var.boot_disk_name != null ? var.boot_disk_name : "${var.name_prefix}-boot-disk"
  linux_vm_name       = var.linux_vm_name != null ? var.linux_vm_name : "${var.name_prefix}-linux-vm"
  vpc_network_name    = var.vpc_network_name != null ? var.vpc_network_name : "${var.name_prefix}-private"
  bucket_sa_name      = var.bucket_sa_name != null ? var.bucket_sa_name : "${var.name_prefix}-bucket-sa"
  bucket_name         = var.bucket_name != null ? var.bucket_name : "${var.name_prefix}-terraform-bucket-${random_string.bucket_name.result}"
  repeated_zones = flatten([
    for zone in var.zones : [
      for i in range(var.vm_count_per_zone) : {
        zone  = zone
        index = i
        key   = "${zone}-${i}"
      }
    ]
  ])
  vm_map = { for z in local.repeated_zones : z.key => z }
}

# Создание дисков и виртуальных машин
resource "yandex_compute_disk" "boot_disk" {
  for_each = local.vm_map

  name     = "${local.boot_disk_name}-${substr(each.value.zone, -1, 0)}-${each.value.index}"
  zone     = each.value.zone
  image_id = var.image_id

  type = var.instance_resources.disk.disk_type
  size = var.instance_resources.disk.disk_size
}

resource "yandex_compute_instance" "this" {
  for_each = local.vm_map

  name = "${local.linux_vm_name}-${substr(each.value.zone, -1, 0)}-${each.value.index}"

  allow_stopping_for_update = true
  platform_id               = var.instance_resources.platform_id
  zone                      = each.value.zone

  resources {
    cores  = var.instance_resources.cores
    memory = var.instance_resources.memory
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot_disk[each.key].id
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private[each.value.zone].id
    nat       = each.value.index == 0 ? true : false
  }

  # Создание дисков до ВМ
  depends_on = [yandex_compute_disk.boot_disk]
}


# Создание VPC и подсети
resource "yandex_vpc_network" "this" {
  name = local.vpc_network_name
}

resource "yandex_vpc_subnet" "private" {
  for_each = var.zones

  name           = keys(var.subnets)[index(tolist(var.zones), each.value)]
  zone           = each.value
  v4_cidr_blocks = var.subnets[each.value]
  network_id     = yandex_vpc_network.this.id
}

resource "yandex_vpc_address" "this" {
  for_each = var.zones

  name = length(var.zones) > 1 ? "${local.linux_vm_name}-address-${substr(each.value, -1, 0)}" : "${local.linux_vm_name}-address"

  external_ipv4_address {
    zone_id = each.value
  }
}

# Создание сервисного аккаунта 
resource "yandex_iam_service_account" "bucket" {
  name = local.bucket_sa_name
}

# Назначение роли сервисному аккаунту
resource "yandex_resourcemanager_folder_iam_member" "storage_editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.bucket.id}"
}

# Создание статического ключа доступа
resource "yandex_iam_service_account_static_access_key" "this" {
  service_account_id = yandex_iam_service_account.bucket.id
  description        = "static access key for object storage"
}

# Создание бакета 
resource "yandex_storage_bucket" "this" {
  bucket     = local.bucket_name
  access_key = yandex_iam_service_account_static_access_key.this.access_key
  secret_key = yandex_iam_service_account_static_access_key.this.secret_key

  depends_on = [yandex_resourcemanager_folder_iam_member.storage_editor]
}

resource "random_string" "bucket_name" {
  length  = 8
  special = false
  upper   = false
}
