# Customer Gateway (represents the GCP side public IP)
resource "aws_customer_gateway" "gcp_cgw" {
  bgp_asn    = 65000
  ip_address = var.customer_gateway_ip
  type       = "ipsec.1"
}

# Virtual Private Gateway
resource "aws_vpn_gateway" "vgw" {
  vpc_id = aws_vpc.this.id
}

resource "aws_vpn_connection" "vpn" {
  vpn_gateway_id = aws_vpn_gateway.vgw.id
  customer_gateway_id = aws_customer_gateway.gcp_cgw.id
  type = "ipsec.1"

  static_routes_only = true
}

resource "aws_vpn_connection_route" "routes" {
  for_each = toset(var.aws_vpn_static_routes)
  vpn_connection_id = aws_vpn_connection.vpn.id
  destination_cidr_block = each.value
}

# Output VPN tunnel info (you must copy PSK from console or set via aws_vpn_connection options if available)
output "aws_vpn_gateway_id" { value = aws_vpn_gateway.vgw.id }
output "aws_vpn_connection_id" { value = aws_vpn_connection.vpn.id }
output "aws_vpc_id" { value = aws_vpc.this.id }