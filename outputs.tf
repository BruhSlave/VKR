# Outputs

output "boot_disk_ids" {
  description = "The IDs of the boot disks created for the instances."
  value = {
    for disk in yandex_compute_disk.boot_disk :
    disk.name => disk.id...
  }
}

output "instance_ids" {
  description = "The IDs of the Yandex Compute instances."
  value = {
    for instance in yandex_compute_instance.this :
    instance.name => instance.id...
  }
}

output "subnet_ids" {
  description = "The IDs of the VPC subnets used by the Yandex Compute instances."
  value = {
    for subnet in yandex_vpc_subnet.private :
    subnet.name => subnet.id...
  }
}

output "service_account_id" {
  description = "The ID of the Yandex IAM service account."
  value       = yandex_iam_service_account.bucket.id
}

output "bucket_name" {
  description = "The name of the Yandex Object Storage bucket."
  value       = yandex_storage_bucket.this.bucket
}

output "nat_vm_external_ips" {
  description = "External VM's IPs with NAT"
  value = {
    for k, vm in yandex_compute_instance.this :
    k => vm.network_interface[0].nat_ip_address
    if vm.network_interface[0].nat
  }
}

output "all_vm_internal_ips" {
  description = "Internal IP's"
  value = {
    for k, vm in yandex_compute_instance.this :
    k => vm.network_interface[0].ip_address
  }
}