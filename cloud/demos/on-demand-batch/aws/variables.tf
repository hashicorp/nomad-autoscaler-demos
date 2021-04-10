# Required variables.
variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones where resources will be created."
}

variable "key_name" {
  type        = string
  description = "The SSH key name used to access instances."
}

variable "owner_name" {
  type        = string
  description = "The name used to identify the owner of the resources provisioned by this module. It will be stored in a tag called OwnerName."
}

variable "owner_email" {
  type        = string
  description = "The email used to contact the owner of the resources provisioned by this module. It will be stored in a tag called OwnerEmail."
}

variable "region" {
  type        = string
  description = "The AWS region where resources will be created."
}

# Optional variables.
variable "allowed_ips" {
  type        = list(string)
  default     = []
  description = "List IPs that will allowed to access the cluster."
}

variable "ami_id" {
  type        = string
  default     = ""
  description = "The AMI ID to use when launching new instances."
}
