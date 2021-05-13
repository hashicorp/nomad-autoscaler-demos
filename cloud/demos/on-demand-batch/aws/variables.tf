# Required variables.
variable "availability_zones" {
  type = list(string)
}
variable "key_name" {}
variable "owner_name" {}
variable "owner_email" {}
variable "region" {}
variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}
# Optional variables.
variable "ami_id" {
  default     = ""
  description = "AMI ID to use to provision instances. If left empty, a new image will be created."
}

variable "allowed_ips" {
  default     = ""
  description = "List of IP addresses allowed to access the infrastructure. If left empty, only the IP of the machine running Terraform will be allowed."
}

variable "nomad_binary_url" {
  default     = "https://releases.hashicorp.com/nomad/1.1.0-rc1/nomad_1.1.0-rc1_linux_amd64.zip"
  description = "Overiding the Nomad Binary url."
}