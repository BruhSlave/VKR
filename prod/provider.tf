terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"

    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
  }
  required_version = ">= 1.00"
}

provider "yandex" {
  zone      = "ru-central1-a"
  folder_id = "b1gsqp3omlusv377dipl"
}

provider "random" {
}