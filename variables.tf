variable "project_id" {
  description = "Google-Cloud-Projekt mit aktivierter Abrechnung."
  type        = string
}

variable "allowed_ip" {
  description = "Deine oeffentliche IPv4-Adresse als CIDR, zum Beispiel 1.2.3.4/32."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.allowed_ip)) && can(regex("/32$", var.allowed_ip))
    error_message = "Bitte eine einzelne IPv4-Adresse mit /32 angeben."
  }
}

variable "name" {
  type    = string
  default = "bigdata-lab"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,38}[a-z0-9]$", var.name))
    error_message = "Name: 2 bis 40 Kleinbuchstaben, Ziffern oder Bindestriche; kein Bindestrich am Ende."
  }
}

variable "zone" {
  type    = string
  default = "europe-west3-a"

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]-[a-z]$", var.zone))
    error_message = "Bitte eine Google-Cloud-Zone wie europe-west3-a angeben."
  }
}

variable "machine_type" {
  type    = string
  default = "n2-highmem-4"
}

variable "disk_size_gb" {
  type    = number
  default = 200

  validation {
    condition     = var.disk_size_gb >= 100 && floor(var.disk_size_gb) == var.disk_size_gb
    error_message = "Mindestens 100 GB als ganze Zahl angeben."
  }
}
