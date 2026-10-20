variable "project_id" {
  type     = string
  nullable = false
}

variable "region" {
  type     = string
  nullable = false
}

variable "zone" {
  type     = string
  nullable = false
}

variable "instance_name" {
  type     = string
  nullable = false
}

variable "network_name" {
  type     = string
  nullable = false
}

variable "subnet_name" {
  type     = string
  nullable = false
}

variable "machine_type" {
  type     = string
  nullable = false
  default  = "e2-standard-2"
}

variable "boot_disk_size_gb" {
  type     = number
  nullable = false
  default  = 40
  validation {
    condition     = var.boot_disk_size_gb > 0 && floor(var.boot_disk_size_gb) == var.boot_disk_size_gb
    error_message = "Der Wert muss eine positive ganze Zahl sein."
  }
}

variable "boot_disk_type" {
  type     = string
  nullable = false
  default  = "pd-balanced"
}

variable "boot_image" {
  type     = string
  nullable = false
  default  = "debian-cloud/debian-12"
}

variable "firewall_name" {
  type     = string
  nullable = false
  default  = "bigdata-ssh-current-ip"
}

variable "max_run_duration_seconds" {
  type     = number
  nullable = false
  default  = 7200
  validation {
    condition     = var.max_run_duration_seconds > 0 && floor(var.max_run_duration_seconds) == var.max_run_duration_seconds
    error_message = "Der Wert muss eine positive ganze Zahl sein."
  }
}

variable "ssh_source_cidr" {
  type     = string
  nullable = false
  validation {
    condition     = can(cidrnetmask(var.ssh_source_cidr)) && endswith(var.ssh_source_cidr, "/32")
    error_message = "ssh_source_cidr muss eine einzelne IPv4 mit /32 sein."
  }
}
