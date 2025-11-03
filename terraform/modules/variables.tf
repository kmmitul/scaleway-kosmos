variable "scw_project_id" {
  type        = string
  description = "Scaleway Project ID"
  default     = "PLACE_HOLDER"
}

variable "gcp_project_id" {
  type        = string
  description = "Google Cloud Project ID"
  default     = "PLACE_HOLDER"
}


variable "scw_profile" {
  type        = string
  description = "Name of the Scaleway Profile which will be used for Terraform authentication"
  default     = "PLACE_HOLDER"
}

variable "aws_profile" {
  type        = string
  description = "Name of the AWS Profile which will be used for Terraform authentication"
  default     = "PLACE_HOLDER"
}

variable "scw_secret_key" {
  description = "Scaleway API Secret Key"
  type        = string
  default     = "PLACE_HOLDER"
}

variable "allowed_ips" {
  description = "One or more IP Addresses, or CIDR Blocks which should be able to access the AWS Instance using SSH."
  type        = list(string)
  default     = ["PLACE_HOLDER"]
}
