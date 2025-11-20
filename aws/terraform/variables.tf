variable "aws_region" { default = "ap-south-1" }
variable "aws_account_id" { type = string }

variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "private_subnet_cidrs" { type = list(string) default = ["10.0.1.0/24","10.0.2.0/24"] }

variable "gcp_vpc_cidr" { type = string } # e.g. 10.50.0.0/16

variable "cloudsql_private_ip" { type = string } # e.g. 10.50.3.10
variable "cloudsql_dbname" { type = string }
variable "cloudsql_user" { type = string }
variable "cloudsql_password" { type = string }

variable "aurora_username" { default = "auroraadmin" }
variable "aurora_password" { type = string }
variable "aurora_dbname" { default = "appdb" }

# VPN
variable "aws_vpn_static_routes" { type = list(string) default = ["10.50.0.0/16"] } # add GCP VPC cidrs
variable "customer_gateway_ip" { type = string } # GCP VPN gateway public IP (if known) -- can be left blank to fill later
variable "vpn_pre_shared_key" { type = string }