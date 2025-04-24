terraform {
  backend "s3" {
    bucket   = "vkr-terraform-state"
    key      = "prod.tfstate"
    endpoint = "https://storage.yandexcloud.net"
    //region   = "ru-central1"
  }
}