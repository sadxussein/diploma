variable "yandex_token" {
  description = "Yandex.Cloud API token"
}

variable "yandex_profile" {
  description = "Name of the Yandex Cloud profile to use"
  default     = "default"
}

variable "cloud_id" {
  description = "Yandex.Cloud ID"
}

variable "folder_id" {
  description = "Yandex.Cloud folder ID"
}

variable "ssh_public_key_path" {
  description = "Путь к открытому SSH ключу для подключения к бастион-серверу"
}