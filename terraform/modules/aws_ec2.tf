data "aws_ami" "ubuntu_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-oracular-24.10-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] #OwnerId for Canonical 
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "security" {
  name   = "allow-komsos"
  vpc_id = data.aws_vpc.default.id
  ingress {
    description = "Allow SSH"
    cidr_blocks = var.allowed_ips
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  # Kubernetes API server communication (worker → control plane)
  ingress {
    description = "Allow kubelet communication"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Kubernetes konnectivity-agent
  ingress {
    description = "Allow Konnectivity-agent communication"
    from_port   = 8134
    to_port     = 8134
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Kubernetes Node Port for Kosmos-LB
  ingress {
    description = "Allow Node Port communication"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "ec2_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_keypair" {
  key_name   = "ec2-key-pair"
  public_key = tls_private_key.ec2_rsa.public_key_openssh
}
#Ec2 Instance
resource "aws_instance" "kosmos_ec2" {
  ami                         = data.aws_ami.ubuntu_ami.id #"ami-07d89ffd477b38a5b" 
  instance_type               = "t3.medium"
  vpc_security_group_ids      = [aws_security_group.security.id]
  key_name                    = aws_key_pair.ec2_keypair.key_name
  associate_public_ip_address = true

  tags = {
    Name = "kosmos-external-node"
  }

}

resource "null_resource" "ec2_kosmos_node_agent" {
  depends_on = [aws_instance.kosmos_ec2, scaleway_k8s_cluster.kosmos_cluster, scaleway_k8s_pool.external_pool]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ec2_rsa.private_key_pem
    host        = aws_instance.kosmos_ec2.public_ip
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
