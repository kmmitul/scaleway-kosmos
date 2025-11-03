data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2410-amd64"
  project = "ubuntu-os-cloud"
}

resource "tls_private_key" "ce_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "google_compute_instance" "ce_kosmos" {
  name                      = "kosmos-external-node"
  machine_type              = "e2-medium"
  zone                      = "europe-west9-a"
  allow_stopping_for_update = true
  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }
  metadata = {
    ssh-keys = "ubuntu:${tls_private_key.ce_rsa.public_key_openssh}"
  }
  tags = ["k8s-worker"]
}


resource "google_compute_firewall" "allow_kubelet" {
  name    = "allow-kubelet"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["10250"]
  }

  source_ranges = ["0.0.0.0/0"]
  direction     = "INGRESS"
  target_tags   = ["k8s-worker"]
}

resource "google_compute_firewall" "allow_konnectivity_agent" {
  name    = "allow-konnectivity-agent"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8134"]
  }

  source_ranges = ["0.0.0.0/0"]
  direction     = "INGRESS"
  target_tags   = ["k8s-worker"]
}

resource "google_compute_firewall" "allow_nodeport" {
  name    = "allow-nodeport"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }

  source_ranges = ["0.0.0.0/0"]
  direction     = "INGRESS"
  target_tags   = ["k8s-worker"]
}


resource "null_resource" "ce_kosmos_node_agent" {
  depends_on = [google_compute_instance.ce_kosmos, scaleway_k8s_cluster.kosmos_cluster, scaleway_k8s_pool.external_pool]
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ce_rsa.private_key_pem
    host        = google_compute_instance.ce_kosmos.network_interface.0.access_config.0.nat_ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo Welcome to Kosmos",
      "wget -nc https://scwcontainermulticloud.s3.fr-par.scw.cloud/node-agent_linux_amd64 && chmod +x node-agent_linux_amd64",
      "export POOL_ID=${split("/", scaleway_k8s_pool.external_pool.id)[1]} POOL_REGION=${scaleway_k8s_pool.external_pool.region}  SCW_SECRET_KEY=${var.scw_secret_key}",
      "sudo -E ./node-agent_linux_amd64 -loglevel 0 -no-controller >> log",
      "sleep 60 && echo Kubelet --> Status: $(systemctl is-active kubelet), Enabled: $(systemctl is-enabled kubelet)",
    ]
  }
}
