output "external_ip" {
  value = google_compute_instance.lab.network_interface[0].access_config[0].nat_ip
}

output "ssh" {
  value = "gcloud compute ssh ${var.name} --project=${var.project_id} --zone=${var.zone}"
}

output "status" {
  value = "gcloud compute ssh ${var.name} --project=${var.project_id} --zone=${var.zone} --command=\"sudo cat /var/lib/bigdata/status; sudo tail -n 30 /var/log/bigdata-setup.log\""
}

output "hive_tunnel" {
  value = "gcloud compute ssh ${var.name} --project=${var.project_id} --zone=${var.zone} -- -N -o ExitOnForwardFailure=yes -L 127.0.0.1:10000:127.0.0.1:31000 -L 127.0.0.1:8088:127.0.0.1:38088 -L 127.0.0.1:9870:127.0.0.1:39870"
}
