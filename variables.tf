variable "subscription_id" {
  description = "ID de la suscripción de Azure donde se desplegarán los recursos."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id debe ser un GUID válido. Obtén el tuyo con: az account show --query id -o tsv"
  }
}

variable "organization" {
  description = "Abreviatura de la organización."
  type        = string
  default     = "utvt"

  validation {
    condition     = can(regex("^[a-z0-9]{2,6}$", var.organization))
    error_message = "organization debe contener de 2 a 6 letras minúsculas o números."
  }
}

variable "project_name" {
  description = "Nombre corto del proyecto o aplicación."
  type        = string
  default     = "portal"

  validation {
    condition     = can(regex("^[a-z0-9]{3,12}$", var.project_name))
    error_message = "project_name debe contener de 3 a 12 letras minúsculas o números."
  }
}

variable "environment" {
  description = "Ambiente donde se desplegarán los recursos."
  type        = string
  default     = "qa"

  validation {
    condition     = contains(["dev", "test", "qa", "stg", "prod"], var.environment)
    error_message = "environment debe ser dev, test, qa, stg o prod."
  }
}

variable "location" {
  description = "Región de Azure donde se desplegarán los recursos."
  type        = string
  default     = "mexicocentral"
}

variable "unique_suffix" {
  description = "Sufijo que hace único en todo Azure el nombre de la cuenta de almacenamiento (por ejemplo, tu nombre o matrícula)."
  type        = string
  default     = "001"

  validation {
    condition     = can(regex("^[a-z0-9]{3,8}$", var.unique_suffix))
    error_message = "unique_suffix debe contener de 3 a 8 letras minúsculas o números."
  }
}

variable "storage_replication_type" {
  description = "Tipo de replicación de la cuenta de almacenamiento."
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS"], var.storage_replication_type)
    error_message = "storage_replication_type debe ser LRS, ZRS, GRS o RAGRS."
  }
}

variable "tags" {
  description = "Etiquetas comunes para los recursos de Azure."
  type        = map(string)
  default = {
    managed_by = "terraform"
  }
}
