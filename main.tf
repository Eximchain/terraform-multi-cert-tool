module "cert_tool" {
  source = "module"

  ca_public_key_file_path = "${path.module}/certs/ca.crt"
  public_key_file_path    = "${path.module}/certs/openvpn.crt"
  private_key_file_path   = "${path.module}/certs/openvpn.pem"
  owner                   = "$USER"
  organization_name       = "Eximchain Pte. Ltd."
  ca_common_name          = "Eximchain OpenVPN Private CA"
  common_name             = "Eximchain OpenVPN Private Certificate"
  domain_prefixes         = ["vpn-us-east", "vpn-us-west", "vpn-singapore"]
  sub_domain              = "eximchain.com"
  ip_addresses            = []
  validity_period_hours   = 8760
}
