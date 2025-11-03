output "external_pool_id" {
  description = "Scaleway External Pool ID"
  value       = scaleway_k8s_pool.external_pool.id
}

output "scaleway_cluster_id" {
  description = "Cluster ID of Kosmos"
  value       = scaleway_k8s_cluster.kosmos_cluster.id
}

output "ce_public_ip" {
  description = "Compute Engine Public IP"
  value       = google_compute_instance.ce_kosmos.network_interface.0.access_config.0.nat_ip
}

output "ec2_public_ip" {
  description = "EC2 Instance Public IP"
  value       = aws_instance.kosmos_ec2.public_ip
}