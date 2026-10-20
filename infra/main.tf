data "google_compute_network" "existing" {
  name = var.network_name
}
data "google_compute_subnetwork" "existing" {
  name   = var.subnet_name
  region = var.region
}
resource "google_compute_firewall" "ssh" {
  name          = var.firewall_name
  network       = data.google_compute_network.existing.self_link
  direction     = "INGRESS"
  priority      = 1000
  source_ranges = [var.ssh_source_cidr]
  target_tags   = ["bigdata-ssh"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
resource "google_compute_instance" "bigdata" {
  name                      = var.instance_name
  zone                      = var.zone
  machine_type              = var.machine_type
  tags                      = ["bigdata-ssh"]
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.boot_disk_size_gb
      type  = var.boot_disk_type
    }
  }
  network_interface {
    network    = data.google_compute_network.existing.self_link
    subnetwork = data.google_compute_subnetwork.existing.self_link
    access_config {}
  }
  # Kein service_account-Block: die VM bekommt keinen Service-Account.
  scheduling {
    automatic_restart           = false
    on_host_maintenance         = "TERMINATE"
    instance_termination_action = "STOP"
    max_run_duration {
      seconds = var.max_run_duration_seconds
    }
  }
  lifecycle {
    prevent_destroy = true
    # gcloud compute ssh verwaltet diese Schluessel ausserhalb von Terraform.
    ignore_changes = [metadata["ssh-keys"]]
    precondition {
      condition     = data.google_compute_subnetwork.existing.network == data.google_compute_network.existing.self_link
      error_message = "Das Subnetz gehoert nicht zum konfigurierten Netzwerk."
    }
  }
}
