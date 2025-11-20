variable "gcp_project" { type = string }
variable "gcp_region" { default = "asia-south1" }
variable "gcp_vpc_name" { default = "mig-gcp-vpc" }
variable "gcp_vpc_cidr" { default = "10.50.0.0/16" }
variable "gcp_subnet_cidr" { default = "10.50.3.0/24" }
variable "aws_vpn_public_ip" { type = string } # AWS VPN public ip from terraform output or console
variable "vpn_pre_shared_key" { type = string }