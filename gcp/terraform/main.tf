resource "google_compute_network" "mig_vpc" {
  name = var.gcp_vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name = "mig-subnet"
  ip_cidr_range = var.gcp_subnet_cidr
  region = var.gcp_region
  network = google_compute_network.mig_vpc.self_link
}

# Cloud Router
resource "google_compute_router" "router" {
  name = "mig-router"
  network = google_compute_network.mig_vpc.self_link
  region = var.gcp_region
}

# Cloud VPN (Classic VPN gateway + Tunnel)
resource "google_compute_vpn_gateway" "vpn_gw" {
  name = "gcp-vpn-gw"
  network = google_compute_network.mig_vpc.self_link
  region = var.gcp_region
}

resource "google_compute_vpn_tunnel" "tunnel" {
  name = "gcp-to-aws-tunnel"
  region = var.gcp_region
  target_vpn_gateway = google_compute_vpn_gateway.vpn_gw.self_link
  peer_ip = var.aws_vpn_public_ip
  shared_secret = var.vpn_pre_shared_key
  ike_version = 2
}

# Static route to AWS VPC via tunnel (assumes one static route)
resource "google_compute_route" "to_aws" {
  name = "to-aws-route"
  network = google_compute_network.mig_vpc.self_link
  dest_range = "10.0.0.0/16" # change to your AWS VPC CIDR
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel.self_link
  priority = 1000
}

output "gcp_vpn_external_ip" {
  value = google_compute_vpn_gateway.vpn_gw.network
}