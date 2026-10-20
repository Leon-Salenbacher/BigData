locals {
  region = substr(var.zone, 0, length(var.zone) - 2)

  # Copy only the exercise environment into VM metadata; no local credentials.
  runtime_files = setunion(
    fileset(path.module, "data/**"),
    fileset(path.module, "setup/*.sh"),
    toset(["compose.yml"])
  )
  install_files = join("\n", [for filename in sort(tolist(local.runtime_files)) :
    join("\n", [
      "mkdir -p '/opt/bigdata/${dirname(filename)}'",
      "base64 -d <<'LAB_FILE' > '/opt/bigdata/${filename}'",
      base64encode(replace(file("${path.module}/${filename}"), "\r\n", "\n")),
      "LAB_FILE"
    ])
  ])
  startup_script = replace(
    replace(file("${path.module}/setup/startup.sh"), "\r\n", "\n"),
    "@@FILES@@", local.install_files
  )
}

resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_compute_network" "lab" {
  name                    = var.name
  auto_create_subnetworks = false
  depends_on              = [google_project_service.compute]
}

resource "google_compute_subnetwork" "lab" {
  name          = var.name
  region        = local.region
  network       = google_compute_network.lab.id
  ip_cidr_range = "10.42.0.0/24"
}

resource "google_compute_firewall" "ssh" {
  name          = "${var.name}-ssh"
  network       = google_compute_network.lab.id
  direction     = "INGRESS"
  source_ranges = [var.allowed_ip]
  target_tags   = [var.name]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_instance" "lab" {
  name         = var.name
  zone         = var.zone
  machine_type = var.machine_type
  tags         = [var.name]

  boot_disk {
    auto_delete = true
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.lab.id
    access_config {}
  }

  # No service_account block: the VM does not need Google API permissions.
  # Metadata changes update the script without replacing the VM and its disk.
  metadata = {
    block-project-ssh-keys = "TRUE"
    startup-script         = local.startup_script
  }

  labels = {
    managed-by = "terraform"
  }

  lifecycle {
    precondition {
      condition     = length(local.startup_script) < 250000
      error_message = "Startup-Skript ist zu gross fuer VM-Metadaten."
    }
  }
}
