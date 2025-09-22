# https://developer.hashicorp.com/packer/guides/hcl/variables
# Packer loads all files ending in .pkr.hcl in a directory and merges them together.
# Packer will automatically load any var file that matches the name *.auto.pkrvars.hcl
# https://developer.hashicorp.com/packer/docs/templates/hcl_templates/functions/contextual/env
# "env" allows you to get the value for an environment variable inside input variables only. 

variable "created_email" { default = "mikael.sikora@hashicorp.com" }
variable "created_name"  { default = "mikael_sikora"}
variable "region"        { default = "us-west-2" }
variable "name_prefix"   { default = "scale-mws" }
variable "architecture"  { default = "amd64" }
variable "os"            { default = "Ubuntu" }
variable "os_version"    { default = "24.04" }
variable "os_name"       { default = "noble" }

# Input variables for version management with hybrid fallback system
variable "cni_version" { 
  description = "CNI plugins version. If empty, will use environment variable or default"
  type        = string
  default     = env("CNIVERSION") != "" ? env("CNIVERSION") : "v1.8.0"
}
variable "consul_template_version" { 
  description = "Consul Template version. If empty, will use environment variable or default"
  type        = string
  default     = env("CONSULTEMPLATEVERSION") != "" ? env("CONSULTEMPLATEVERSION") : "0.41.2"
}
variable "consul_version" { 
  description = "Consul version. If empty, will use environment variable or default"
  type        = string
  default     = env("CONSULVERSION") != "" ? env("CONSULVERSION") : "1.21.4"
}
variable "nomad_version" { 
  description = "Nomad version. If empty, will use environment variable or default"
  type        = string
  default     = env("NOMADVERSION") != "" ? env("NOMADVERSION") : "1.10.5"
}
variable "vault_version" { 
  description = "Vault version. If empty, will use environment variable or default"
  type        = string
  default     = env("VAULTVERSION") != "" ? env("VAULTVERSION") : "1.20.3"
}
