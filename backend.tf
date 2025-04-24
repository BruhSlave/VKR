terraform {
  backend "s3" {
    bucket   = "vkr-terraform-state"
    key      = "prod.tfstate"                
    endpoint = "https://storage.yandexcloud.net"
    region   = "ru-central1"
    access_key = var.access_key              
    secret_key = var.secret_key
  }
}