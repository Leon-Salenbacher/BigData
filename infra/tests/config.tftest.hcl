mock_provider "google" {
  mock_data "google_compute_network" {
    defaults = {
      self_link = "https://www.googleapis.com/compute/v1/projects/test-project/global/networks/default"
    }
  }
  mock_data "google_compute_subnetwork" {
    defaults = {
      self_link = "https://www.googleapis.com/compute/v1/projects/test-project/regions/europe-west3/subnetworks/default"
      network   = "https://www.googleapis.com/compute/v1/projects/test-project/global/networks/default"
    }
  }
}

variables {
  project_id      = "test-project"
  region          = "europe-west3"
  zone            = "europe-west3-a"
  instance_name   = "bigdata-test"
  network_name    = "default"
  subnet_name     = "default"
  ssh_source_cidr = "203.0.113.42/32"
}

run "infrastructure_plan" {
  command = plan
  assert {
    condition     = google_compute_firewall.ssh.source_ranges == toset(["203.0.113.42/32"])
    error_message = "SSH muss auf die einzelne konfigurierte IP beschraenkt sein."
  }
  assert {
    condition     = length(google_compute_instance.bigdata.service_account) == 0
    error_message = "Die VM darf keinen Service-Account erhalten."
  }
  assert {
    condition     = google_compute_instance.bigdata.scheduling[0].max_run_duration[0].seconds == 7200 && google_compute_instance.bigdata.scheduling[0].instance_termination_action == "STOP"
    error_message = "Die VM muss nach zwei Stunden stoppen."
  }
}

run "reject_broad_ssh_access" {
  command = plan
  variables {
    ssh_source_cidr = "0.0.0.0/0"
  }
  expect_failures = [var.ssh_source_cidr]
}

run "reject_wrong_network" {
  command = plan
  override_data {
    target = data.google_compute_subnetwork.existing
    values = {
      network = "https://www.googleapis.com/compute/v1/projects/test-project/global/networks/other"
    }
  }
  expect_failures = [google_compute_instance.bigdata]
}
