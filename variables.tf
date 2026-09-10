variable "environment" {
  description = "Ambiente (dev, hom, prd)"
  type        = string
  default     = "dev"
}

variable "vm_config" {
  description = "Configurações da VM"
  type = object({
    name          = string
    memory        = number
    vcpus         = number
    disk_size_gb  = number
    disk_size_mb  = number
    swap_size_mb  = number
    ip            = string
    gateway       = string
    netmask       = string
    dns           = string
    hostname      = string
    iso_path      = string
    disk_path     = string
    network       = string
    timezone      = string
    root_password_hash = string
    user_name     = string
    user_password_hash = string
  })
}
