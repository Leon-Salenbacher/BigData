output "instance_name" {
  value = google_compute_instance.bigdata.name
}
output "external_ip" {
  value = google_compute_instance.bigdata.network_interface[0].access_config[0].nat_ip
}
output "ssh_source_cidr" {
  value = var.ssh_source_cidr
}
